#!/bin/sh
# Acilistan sonra: depo kontrolu ve print-agent yenileme.
set -u
GUNC_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$GUNC_DIR")"
. "$GUNC_DIR/pi-env.sh"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "[KIOSK] pi-boot-update-check: $(date -Iseconds 2>/dev/null || date)"
echo "[KIOSK] APPS_ROOT=$SIRAMATIK_APPS_ROOT KIOSK=$SIRAMATIK_KIOSK_DIR"

if sh "$GUNC_DIR/pi-git-pull-if-needed.sh"; then
	echo "[KIOSK] Depo guncellendi."
	if command -v systemctl >/dev/null 2>&1; then
		systemctl try-restart siramatik-print-agent.service 2>/dev/null || true
	fi
	exit 0
fi
ex=$?
if [ "$ex" -eq 1 ]; then
	echo "[KIOSK] Depo zaten guncel veya kontrol atlandi (cikis 1)."
	exit 0
fi
echo "[KIOSK] Guncelleme basarisiz (cikis $ex)." >&2
exit "$ex"
