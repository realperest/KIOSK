#!/bin/sh
# SIRAMATIK deposunu manuel guncelle (pip/venv yok).
set -eu
GUNC_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$GUNC_DIR")"
. "$GUNC_DIR/pi-env.sh"
REPO="$(siramatik_resolve_repo_root "$KIOSK_DIR")" || {
	echo "HATA: Git deposu bulunamadi (SIRAMATIK_REPO veya monorepo)." >&2
	exit 1
}
cd "$REPO"

if ! test -d .git; then
	echo "HATA: Git deposu yok: $REPO" >&2
	exit 1
fi

git pull --ff-only
echo "OK: guncellendi -> $REPO ($(git -C "$REPO" rev-parse --short HEAD))"
