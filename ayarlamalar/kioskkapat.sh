#!/bin/bash
# ==============================================================================
# kioskkapat.sh - SIRAMATIK KIOSK KAPATMA VE TEMIZLIK
# Otobaslatma kayitlari ve baslatici script kaldirilir (kioskyap ile ayni yollar).
# ==============================================================================

AYARLAMALAR_DIR="$(cd "$(dirname "$0")" && pwd)"
LAUNCHER_SCRIPT="$AYARLAMALAR_DIR/siramatik-kiosk-run.sh"
XDG_AUTOSTART_FILE="$HOME/.config/autostart/siramatik_kiosk.desktop"
WAYFIRE_CONFIG="$HOME/.config/wayfire.ini"
LABWC_AUTOSTART_FILE="$HOME/.config/labwc/autostart"

echo "----------------------------------------------------------"
echo "SIRAMATIK KIOSK KAPATMA (TEMIZLIK) BASLIYOR..."
echo "----------------------------------------------------------"

if [ -f "$LAUNCHER_SCRIPT" ]; then
	rm "$LAUNCHER_SCRIPT"
	echo "   > Kiosk baslatici silindi."
fi

if [ -f "$XDG_AUTOSTART_FILE" ]; then
	rm "$XDG_AUTOSTART_FILE"
	echo "   > XDG Autostart kaydi silindi."
fi

if [ -f "$WAYFIRE_CONFIG" ]; then
	sed -i "/siramatik_kiosk/d" "$WAYFIRE_CONFIG"
	echo "   > Wayfire kaydi temizlendi."
fi

if [ -f "$LABWC_AUTOSTART_FILE" ]; then
	sed -i '/siramatik-kiosk-run\.sh/d' "$LABWC_AUTOSTART_FILE"
	sed -i '/kiosk-print-agent/d' "$LABWC_AUTOSTART_FILE"
	sed -i '/SIRA_YAZICI/d' "$LABWC_AUTOSTART_FILE"
	echo "   > Labwc kiosk satirlari temizlendi."
fi

pkill chromium 2>/dev/null
pkill chromium-browser 2>/dev/null

echo "----------------------------------------------------------"
echo "BASARILI! Kiosk otobaslatma kaldirildi, tarayici sonlandirildi."
echo "----------------------------------------------------------"
