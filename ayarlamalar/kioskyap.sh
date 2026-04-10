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
# kiosk = Chromium --kiosk (kilitli, parmakla 'tam ekrandan cik' yok; halka acik terminal icin uygun)
# app    = --app + --start-fullscreen (daha az kilitli; F11 / jestler WM'ye gore fark edebilir)
CHROME_UI_MODE="${SIRAMATIK_KIOSK_CHROME_MODE:-kiosk}"

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
echo "  Chromium: $CHROME_UI_MODE (SIRAMATIK_KIOSK_CHROME_MODE=app ile uygulama+tam ekran)"
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

# Profil bu dizinde; ~/.config/chromium degil (yanlis yol incognito/profil karisikligine yol acabilir)
mkdir -p "$USER_DATA_DIR/Default"
touch "$USER_DATA_DIR/Default/Preferences" 2>/dev/null
sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "$USER_DATA_DIR/Default/Preferences" 2>/dev/null

# kioskyap calisirken sabitlenen mod: $CHROME_UI_MODE
MODE="$CHROME_UI_MODE"
if [ "\$MODE" = "app" ]; then
	$CHROME_CMD --app="$URL" --start-fullscreen \\
	    --user-data-dir="$USER_DATA_DIR" \\
	    --profile-directory=Default \\
	    --no-first-run \\
	    --ozone-platform-hint=auto \\
	    --force-device-scale-factor=1.00 \\
	    --noerrdialogs \\
	    --disable-infobars \\
	    --hide-crash-restore-bubble \\
	    --disk-cache-size=1 \\
	    --media-cache-size=1 &
else
	# --kiosk: Android tablet jesti gibi kenardan cekerek cikis OLMAZ (halka acik kiosk icin)
	$CHROME_CMD --kiosk "$URL" \\
	    --user-data-dir="$USER_DATA_DIR" \\
	    --profile-directory=Default \\
	    --no-first-run \\
	    --ozone-platform-hint=auto \\
	    --force-device-scale-factor=1.00 \\
	    --noerrdialogs \\
	    --disable-infobars \\
	    --hide-crash-restore-bubble \\
	    --disk-cache-size=1 \\
	    --media-cache-size=1 &
fi

sleep 12
command -v wtype >/dev/null 2>&1 && wtype -k F11
EOF
chmod +x "$LAUNCHER_SCRIPT"
echo "   > Wayland uyumlu baslatici olusturuldu: $LAUNCHER_SCRIPT"

# --- Otobaslatma: LABWC + XDG ikisi birden calisirsa launcher IKI KEZ acilir;
# script basindaki pkill ilk Chromium'u oldurur -> "acildi kapandi tekrar acildi" etkisi.
USE_LABWC=false
if [ -f "/usr/bin/labwc" ] || [ -d "$LABWC_AUTOSTART_DIR" ]; then
	USE_LABWC=true
fi

if [ "$USE_LABWC" = true ]; then
	rm -f "$XDG_AUTOSTART_FILE"
	echo "   > Labwc oturumu: ~/.config/autostart/siramatik_kiosk.desktop kaldirildi (cift tetikleme onlendi)."
	mkdir -p "$LABWC_AUTOSTART_DIR"
	touch "$LABWC_AUTOSTART_FILE"
	# Eski / yinelenen kiosk satirlarini temizle (SIRA_YAZICI, onceki KIOSK yollari)
	sed -i '/siramatik-kiosk-run\.sh/d' "$LABWC_AUTOSTART_FILE"
	sed -i '/kiosk-print-agent/d' "$LABWC_AUTOSTART_FILE"
	sed -i '/SIRA_YAZICI/d' "$LABWC_AUTOSTART_FILE"
	echo "$LAUNCHER_SCRIPT" >> "$LABWC_AUTOSTART_FILE"
	chmod +x "$LABWC_AUTOSTART_FILE"
	echo "   > Labwc autostart (tek satir): $LAUNCHER_SCRIPT"
	if [ -f "$WAYFIRE_CONFIG" ] && grep -q "siramatik_kiosk" "$WAYFIRE_CONFIG" 2>/dev/null; then
		echo "   > UYARI: ~/.config/wayfire.ini icinde siramatik_kiosk var; Labwc kullaniyorsan bu satirlari silin (cift baslatma)."
	fi
else
	mkdir -p "$XDG_AUTOSTART_DIR"
	cat <<EOF > "$XDG_AUTOSTART_FILE"
[Desktop Entry]
Type=Application
Name=Siramatik Kiosk
Exec=$LAUNCHER_SCRIPT
X-GNOME-Autostart-enabled=true
EOF
	echo "   > XDG autostart: $XDG_AUTOSTART_FILE"
	if [ -f "$WAYFIRE_CONFIG" ]; then
		if ! grep -q "siramatik_kiosk" "$WAYFIRE_CONFIG"; then
			echo -e "\n[autostart]\nsiramatik_kiosk = $LAUNCHER_SCRIPT" >> "$WAYFIRE_CONFIG"
			echo "   > Wayfire otobaslatma kaydi eklendi."
		fi
	fi
fi

echo "----------------------------------------------------------"
echo "BASARILI! Wayland (Bookworm) uyumlulugu saglandi."
echo "Gerekirse: git -C \"$GIT_REPO_ECHO\" pull && bash \"$AYARLAMALAR_DIR/kioskyap.sh\""
echo "Ardindan: sudo reboot"
echo "----------------------------------------------------------"
