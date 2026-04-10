# KIOSK klasörü — dosya açıklamaları

Pi üzerinde tipik yol: `/home/alper/apps/KIOSK/`. Aşağıdaki yollar bu köke göredir.

## Kök dizin

| Dosya | Ne işe yarar |
|--------|----------------|
| `KURULUM.txt` | Pi kurulum adımları, ortam değişkenleri ve systemd özeti (düz metin). |
| `dosya_aciklamaları.md` | Bu tablo: her dosyanın kısa işlev özeti. |

## `ayarlamalar/`

| Dosya | Ne işe yarar |
|--------|----------------|
| `kioskyap.sh` | Chromium’u tam ekran kiosk olarak açar; oturum profili, XDG/Wayfire/Labwc otobaşlatma kayıtlarını yazar; `wtype` ile F11 tetikler. |
| `kioskkapat.sh` | Kiosk otobaşlatma kayıtlarını ve üretilen `siramatik-kiosk-run.sh` dosyasını kaldırır; Chromium süreçlerini sonlandırır. |
| `pi-exit-fullscreen-once.sh` | Yazdırma aracı olmadan tek seferlik tam ekrandan çıkmak için `wtype` ile F11 gönderir. |
| `master_setup_raspberry.sh` | Yeni Pi’de Chromium bayrakları, labwc dokunmatik, systemd servis kopyalama ve KIOSK betiklerine çalıştırma izni verir (`scripts/` ile aynı içerik). |
| `siramatik-kiosk-run.sh` | *Yerelde oluşur* — `kioskyap.sh` tarafından üretilen Chromium başlatıcı betiği (repoya genelde commit edilmez). |
| `.kiosk-profile/` | *Yerelde oluşur* — Chromium kullanıcı profili dizini (`.gitignore` ile hariç tutulur). |

## `guncellemeler/`

| Dosya | Ne işe yarar |
|--------|----------------|
| `pi-env.sh` | `SIRAMATIK_APPS_ROOT`, `SIRAMATIK_KIOSK_DIR`, `SIRAMATIK_REPO` varsayılanları; `siramatik_resolve_repo_root` ile git kökünü çözer (Pi: `~/apps/SIRAMATIK`, geliştirme: monorepo üstü). |
| `pi-git-pull-if-needed.sh` | Git’te `origin` ile yerel arasında fark varsa `git pull --ff-only` yapar; güncelleme yoksa çıkış 1, hata 2. |
| `pi-apply-updates.sh` | `pi-git-pull-if-needed` çalıştırır; root’tan `siramatik-print-agent` servisini yeniden başlatır (systemd zamanlayıcı ile uyumlu). |
| `pi-boot-update-check.sh` | Açılış sonrası depo kontrolü ve isteğe bağlı print-agent yenileme (log çıktılı). |
| `pi-update-from-git.sh` | SIRAMATIK deposunda elle tam `git pull --ff-only` (pip gerekmez). |

## `printer/`

| Dosya | Ne işe yarar |
|--------|----------------|
| `main.py` | Yerel HTTP yazdırma aracı: `GET /health`, `POST /print` (base64 ESC/POS), `POST /test-print`, `POST /api/system/exit-fullscreen` (F11). Varsayılan `127.0.0.1:9131`, cihaz `/dev/usb/lp0`. |
| `boot-print-agent.sh` | Eski `main.py` sürecini temizler; `guncellemeler/pi-git-pull-if-needed.sh` ile depoyu güncellemeyi dener; ardından `python3 main.py` çalıştırır (systemd `ExecStart` hedefi). |
| `requirements.txt` | Bilgi amaçlı: harici pip paketi yok, Python 3.9+ yeterli. |
| `siramatik-print-agent.service` | systemd birimi şablonu: print-agent’ı `boot-print-agent.sh` ile başlatır; `User`/`Group` ve yollar Pi kullanıcısına göre düzenlenmeli. |
| `siramatik-print-agent-pull.service` | Zamanlayıcının tetiklediği oneshot: `guncellemeler/pi-apply-updates.sh` çalıştırır. |
| `siramatik-print-agent-pull.timer` | Günlük/periyodik güncelleme zamanlaması (ör. açılıştan ~10 dk sonra ve belirli saatler). |

---

*Son yapı: `ayarlamalar`, `guncellemeler`, `printer` alt klasörleri; `SIRA_YAZICI` yolu kullanılmaz.*
