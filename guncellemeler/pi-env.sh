#!/bin/sh
# Raspberry Pi: KIOSK ve git deposu yollari (tek kaynak).
# Ortam degiskenleri ile ezilebilir. Bu dosya diger betiklerce ' . ' ile yuklenir.

SIRAMATIK_APPS_ROOT="${SIRAMATIK_APPS_ROOT:-/home/alper/apps}"
SIRAMATIK_KIOSK_DIR="${SIRAMATIK_KIOSK_DIR:-$SIRAMATIK_APPS_ROOT/KIOSK}"
SIRAMATIK_REPO="${SIRAMATIK_REPO:-$SIRAMATIK_APPS_ROOT/SIRAMATIK}"

# KIOSK_DIR: bu betiklerin bulundugu KIOSK kok dizini (genelde SCRIPT_DIR).
# Oncelik: Pi yerlesimi $SIRAMATIK_APPS_ROOT/KIOSK altinda .git olmayan KIOSK;
# yoksa gelistirme: depo kokunun altindaki KIOSK (ust dizinde .git).
siramatik_resolve_repo_root() {
	_kd="$1"
	if [ -d "${SIRAMATIK_REPO}/.git" ]; then
		printf '%s\n' "$SIRAMATIK_REPO"
		return 0
	fi
	_parent="$(dirname "$_kd")"
	if [ -d "$_parent/.git" ]; then
		printf '%s\n' "$_parent"
		return 0
	fi
	return 1
}
