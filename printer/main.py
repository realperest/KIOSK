"""
Sıramatik - Kiosk yerel yazdırma aracı (Raspberry Pi / termal USB).

Yalnızca Python standart kütüphanesi; pip / venv gerekmez.
Yapılandırma: PRINT_LISTEN_HOST, PRINT_LISTEN_PORT, PRINT_DEVICE

Opsiyonel (geri besleme / marka komutlari):
  PRINT_JOB_PREFIX_HEX — POST /print ile gelen ham baytlarin BASINA eklenecek hex dizisi
    (bosluk yok veya sorun degil; ornek: 1b6501 = ESC e 1). Cogu termal yazici fiziksel
    olarak geri cekemez ve ESC e yoksayilir; marka dokumanina gore burada doğru diziyi
    verin (or. bazı Sunmi: 1b4b64).
Uçlar: GET /health, POST /print (JSON {"data_base64":"..."}), POST /test-print
"""
from __future__ import annotations

import base64
import json
import logging
import os
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import urlparse

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("kiosk-print-agent")


def _env_str(key: str, default: str) -> str:
    v = os.environ.get(key)
    return (v if v is not None else default).strip()


LISTEN_HOST = _env_str("PRINT_LISTEN_HOST", "127.0.0.1")
try:
    LISTEN_PORT = int(_env_str("PRINT_LISTEN_PORT", "9131"))
except ValueError:
    LISTEN_PORT = 9131

PRINT_DEVICE = _env_str("PRINT_DEVICE", "/dev/usb/lp0")


def _hex_bytes_from_env(key: str) -> bytes:
    hx = _env_str(key, "")
    if not hx:
        return b""
    try:
        return bytes.fromhex(hx.replace(" ", "").replace(":", ""))
    except ValueError:
        logger.warning("%s gecersiz hex, yok sayildi", key)
        return b""


def rawbt_normalize_ascii(s: str) -> str:
    m = str.maketrans(
        "İıŞşĞğÜüÖöÇç",
        "IiSsGgUuOoCc",
    )
    return (s or "").translate(m)


class PrintAgentHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _parsed_path(self) -> str:
        """Yol sonundaki / ve bosluk gibi farklari normalize et."""
        p = urlparse(self.path).path or "/"
        p = p.strip()
        if len(p) > 1 and p.endswith("/"):
            p = p[:-1]
        return p

    def log_message(self, fmt: str, *args: Any) -> None:
        logger.info("%s - %s", self.address_string(), fmt % args)

    def _cors(self) -> None:
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header(
            "Access-Control-Allow-Headers",
            "Content-Type, Access-Control-Request-Private-Network",
        )
        # Chromium: https://genel-site.com sayfasindan http://127.0.0.1 (ozel ag) — PNA preflight
        self.send_header("Access-Control-Allow-Private-Network", "true")

    def _send_json(self, code: int, obj: dict) -> None:
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, code: int, text: str) -> None:
        b = text.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(b)))
        self._cors()
        self.end_headers()
        self.wfile.write(b)

    def do_OPTIONS(self) -> None:
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self) -> None:
        if self._parsed_path() == "/health":
            exists = os.path.exists(PRINT_DEVICE)
            writable = bool(exists and os.access(PRINT_DEVICE, os.W_OK))
            self._send_json(
                200,
                {
                    "ok": bool(exists and writable),
                    "device": PRINT_DEVICE,
                    "exists": exists,
                    "writable": writable,
                    "listen": f"{LISTEN_HOST}:{LISTEN_PORT}",
                },
            )
            return
        self._send_text(404, "Not Found")

    def do_POST(self) -> None:
        path = self._parsed_path()
        if path == "/test-print":
            line = rawbt_normalize_ascii("SIRAMATIK YAZICI TESTI\n")
            payload = (
                bytes([0x1B, 0x40])
                + line.encode("ascii", errors="replace")
                + b"\n\n"
                + bytes([0x1D, 0x56, 0x00])
            )
            try:
                with open(PRINT_DEVICE, "wb", buffering=0) as fp:
                    fp.write(payload)
            except OSError as exc:
                logger.exception("Test yazdirma: %s", exc)
                self._send_json(503, {"detail": "Test yazdirilamadi."})
                return
            logger.info("Test fis: %s bayt", len(payload))
            self._send_json(200, {"status": "ok", "bytes": len(payload)})
            return

        if path == "/api/system/exit-fullscreen":
            try:
                import subprocess
                # wtype ile F11 tuş baskısı simüle edilir (Tam ekrandan çıkış için)
                subprocess.run(["wtype", "-k", "F11"], check=False)
                logger.info("Tam ekrandan cikis emri (F11) gonderildi.")
                self._send_json(200, {"status": "ok", "message": "F11 gonderildi"})
            except Exception as exc:
                logger.exception("F11 hatasi: %s", exc)
                self._send_json(500, {"status": "error", "detail": str(exc)})
            return

        if path != "/print":
            self._send_text(404, "Not Found")
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            length = 0
        if length <= 0 or length > 32 * 1024 * 1024:
            self._send_json(400, {"detail": "Gecersiz Content-Length"})
            return
        try:
            raw_body = self.rfile.read(length)
            data = json.loads(raw_body.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            logger.warning("JSON hatasi: %s", exc)
            self._send_json(400, {"detail": "Gecersiz JSON"})
            return

        b64 = data.get("data_base64") if isinstance(data, dict) else None
        if not b64 or not isinstance(b64, str):
            self._send_json(400, {"detail": "data_base64 gerekli"})
            return
        try:
            raw = base64.b64decode(b64)
        except Exception as exc:
            logger.warning("Base64: %s", exc)
            self._send_json(400, {"detail": "Gecersiz base64"})
            return
        if not raw:
            self._send_json(400, {"detail": "Bos veri"})
            return
        prefix = _hex_bytes_from_env("PRINT_JOB_PREFIX_HEX")
        payload = prefix + raw
        try:
            with open(PRINT_DEVICE, "wb", buffering=0) as fp:
                fp.write(payload)
                try:
                    os.fsync(fp.fileno())
                except OSError:
                    pass
        except OSError as exc:
            logger.exception("Yazdir: %s", exc)
            self._send_json(
                503,
                {"detail": "Yazici cihazina yazilamadi."},
            )
            return
        logger.info("Yazdirildi: %s bayt (prefix=%s)", len(payload), len(prefix))
        self._send_json(200, {"status": "ok", "bytes": len(payload)})


def main() -> None:
    server = ThreadingHTTPServer((LISTEN_HOST, LISTEN_PORT), PrintAgentHandler)
    logger.info(
        "Dinleniyor http://%s:%s cihaz=%s (stdlib, pip yok)",
        LISTEN_HOST,
        LISTEN_PORT,
        PRINT_DEVICE,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Durduruluyor...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
    sys.exit(0)
