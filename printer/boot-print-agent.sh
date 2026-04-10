#!/bin/sh
# Tablet/Pi acilisinda: varsa eski main.py durdur, (mumkunse) git pull, sonra kesinlikle main.py.
# Calisma dizini: /home/alper/apps/KIOSK/printer

set -u
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$SCRIPT_DIR")"
GUNC_DIR="${KIOSK_DIR}/guncellemeler"
if [ -f "$GUNC_DIR/pi-env.sh" ]; then
	. "$GUNC_DIR/pi-env.sh"
fi

kill_same_agent() {
	pkill -f "${SCRIPT_DIR}/main.py" 2>/dev/null || true
	for pid in $(pgrep -u "$(id -un)" -f "python3 main.py" 2>/dev/null || true); do
		[ -n "${pid:-}" ] || continue
		cwd="$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)"
		[ "$cwd" = "$SCRIPT_DIR" ] || continue
		kill "$pid" 2>/dev/null || true
	done
	sleep 0.5
}

git_pull_if_behind() {
	if [ -f "${GUNC_DIR}/pi-git-pull-if-needed.sh" ]; then
		sh "${GUNC_DIR}/pi-git-pull-if-needed.sh" || true
	else
		true
	fi
}

kill_same_agent || true
git_pull_if_behind || true
cd "$SCRIPT_DIR" || exit 1

# systemd User=alper ile baslarken XDG_RUNTIME_DIR bos kalir; wtype Wayland icin gerekir.
# Yeni main.py cikista pkill kullanir; eski surum veya yedek F11 icin yine faydali.
UID_NUM="$(id -u)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID_NUM}"
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	for w in wayland-0 wayland-1; do
		if [ -S "$XDG_RUNTIME_DIR/$w" ] 2>/dev/null; then
			export WAYLAND_DISPLAY="$w"
			break
		fi
	done
fi
: "${WAYLAND_DISPLAY:=wayland-0}"

exec python3 main.py
