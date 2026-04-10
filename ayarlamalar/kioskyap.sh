#!/bin/bash
# ==============================================================================
# kioskyap.sh - SIRAMATIK KIOSK TAM OTOMATIK BASLATMA (WAYLAND UYUMLU v5)
# Pi yerlesimi: /home/alper/apps/KIOSK/ayarlamalar/kioskyap.sh
# ==============================================================================

AYARLAMALAR_DIR="$(cd "$(dirname "$0")" && pwd)"
KIOSK_DIR="$(dirname "$AYARLAMALAR_DIR")"
if [ -f "$KIOSK_DIR/guncellemeler/pi-env.sh" ]; then
	. "$KIOSK_DIR/guncellemeler/pi-env.sh"
fi
SIRAMATIK_APPS_ROOT="${SIRAMATIK_APPS_ROOT:-/home/alper/apps}"
GIT_REPO_ECHO="${SIRAMATIK_REPO:-$SIRAMATIK_APPS_ROOT/SIRAMATIK}"

URL="${SIRAMATIK_KIOSK_URL:-https://siramatik.inovathinks.com/kiosk.html}"

LAUNCHER_SCRIPT="$AYARLAMALAR_DIR/siramatik-kiosk-run.sh"
USER_DATA_DIR="$AYARLAMALAR_DIR/.kiosk-profile"

XDG_AUTOSTART_DIR="$HOME/.config/autostart"
XDG_AUTOSTART_FILE="$XDG_AUTOSTART_DIR/siramatik_kiosk.desktop"
WAYFIRE_CONFIG="$HOME/.config/wayfire.ini"
LABWC_AUTOSTART_DIR="$HOME/.config/labwc"
LABWC_AUTOSTART_FILE="$LABWC_AUTOSTART_DIR/autostart"

echo "----------------------------------------------------------"
echo "SIRAMATIK KIOSK YAPILANDIRMASI (WAYLAND MODU) BASLIYOR..."
echo "  apps: $SIRAMATIK_APPS_ROOT"
echo "  KIOSK: $KIOSK_DIR"
echo "  git depo (beklenen): $GIT_REPO_ECHO"
echo "----------------------------------------------------------"

rm -f "$HOME/.siramatik-kiosk-run.sh"

if ! command -v wtype &> /dev/null; then
	sudo apt-get update && sudo apt-get install wtype -y
fi

CHROME_CMD="chromium-browser"
if command -v chromium &> /dev/null; then
	CHROME_CMD="chromium"
fi

cat <<EOF > "$LAUNCHER_SCRIPT"
#!/bin/bash
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_RUNTIME_DIR=/run/user/\$(id -u)

pkill -f chromium 2>/dev/null
sleep 2

sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' ~/.config/chromium/Default/Preferences 2>/dev/null

$CHROME_CMD --app="$URL" \\
    --start-fullscreen \\
    --user-data-dir="$USER_DATA_DIR" \\
    --ozone-platform-hint=auto \\
    --force-device-scale-factor=1.00 \\
    --noerrdialogs \\
    --disable-infobars \\
    --hide-crash-restore-bubble \\
    --disk-cache-size=1 \\
    --media-cache-size=1 &

sleep 15
wtype -k F11
EOF
chmod +x "$LAUNCHER_SCRIPT"
echo "   > Wayland uyumlu baslatici olusturuldu: $LAUNCHER_SCRIPT"

mkdir -p "$XDG_AUTOSTART_DIR"
cat <<EOF > "$XDG_AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Siramatik Kiosk
Exec=$LAUNCHER_SCRIPT
X-GNOME-Autostart-enabled=true
EOF

if [ -f "$WAYFIRE_CONFIG" ]; then
	if ! grep -q "siramatik_kiosk" "$WAYFIRE_CONFIG"; then
		echo -e "\n[autostart]\nsiramatik_kiosk = $LAUNCHER_SCRIPT" >> "$WAYFIRE_CONFIG"
		echo "   > Wayfire otobaslatma kaydi eklendi."
	fi
fi

if [ -d "$LABWC_AUTOSTART_DIR" ] || [ -f "/usr/bin/labwc" ]; then
	mkdir -p "$LABWC_AUTOSTART_DIR"
	if [ ! -f "$LABWC_AUTOSTART_FILE" ] || ! grep -q "$LAUNCHER_SCRIPT" "$LABWC_AUTOSTART_FILE"; then
		echo "$LAUNCHER_SCRIPT" >> "$LABWC_AUTOSTART_FILE"
		chmod +x "$LABWC_AUTOSTART_FILE"
		echo "   > Labwc otobaslatma kaydi eklendi."
	fi
fi

echo "----------------------------------------------------------"
echo "BASARILI! Wayland (Bookworm) uyumlulugu saglandi."
echo "Gerekirse: git -C \"$GIT_REPO_ECHO\" pull && bash \"$AYARLAMALAR_DIR/kioskyap.sh\""
echo "Ardindan: sudo reboot"
echo "----------------------------------------------------------"
