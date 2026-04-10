#!/bin/sh
# Git deposunda origin ile fark varsa ff-only pull.
# Pi: depo /home/alper/apps/SIRAMATIK, KIOSK /home/alper/apps/KIOSK/guncellemeler (bu betik)
# Gelistirme: .../SIRAMATIK/KIOSK/guncellemeler -> depo kok .../SIRAMATIK
# Cikis: 0 = guncelleme yapildi, 1 = zaten guncel, 2 = pull basarisiz
set -u
GUNC_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$GUNC_DIR")"
. "$GUNC_DIR/pi-env.sh"
REPO_ROOT="$(siramatik_resolve_repo_root "$KIOSK_DIR")" || {
	echo "pi-git-pull-if-needed: Git deposu bulunamadi. SIRAMATIK_REPO=${SIRAMATIK_REPO} veya monorepo KIOSK yerlesimini kontrol edin." >&2
	exit 1
}
cd "$REPO_ROOT" || exit 1
[ -d .git ] || exit 1
git fetch -q origin || exit 1
BR="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)" || exit 1
[ -n "$BR" ] || exit 1
git rev-parse --verify "origin/${BR}" >/dev/null 2>&1 || exit 1
L="$(git rev-parse HEAD 2>/dev/null)" || exit 1
R="$(git rev-parse "origin/${BR}" 2>/dev/null)" || exit 1
[ "$L" != "$R" ] || exit 1
git pull --ff-only origin "$BR" || exit 2
exit 0
