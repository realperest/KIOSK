#!/bin/sh
# Root (systemd oneshot) veya depo sahibi kullanici.
set -u
GUNC_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$GUNC_DIR")"
. "$GUNC_DIR/pi-env.sh"
GIT_USER="${SIRAMATIK_GIT_USER:-alper}"

_pull() {
	if [ "$(id -u)" -eq 0 ] && id "$GIT_USER" >/dev/null 2>&1; then
		runuser -u "$GIT_USER" -- sh "$GUNC_DIR/pi-git-pull-if-needed.sh"
		return $?
	fi
	sh "$GUNC_DIR/pi-git-pull-if-needed.sh"
	return $?
}

if _pull; then
	if [ "$(id -u)" -eq 0 ] && command -v systemctl >/dev/null 2>&1; then
		systemctl try-restart siramatik-print-agent.service 2>/dev/null || true
	fi
	exit 0
fi
ex=$?
[ "$ex" -eq 1 ] && exit 0
exit "$ex"
