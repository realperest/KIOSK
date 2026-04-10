#!/bin/bash

# ==============================================================================
# SIRAMATIK KIOSK MASTER SETUP SCRIPT (v1.0)
# Bu script, yeni bir Raspberry Pi cihazını Sıramatik kiosk sistemine uygun
# hale getirmek için gerekli tüm OS, tarayıcı ve servis ayarlarını otomatik yapar.
# Kopya: scripts/master_setup_raspberry.sh ile aynı içerik (Pi: ~/apps/KIOSK/ayarlamalar).
# ==============================================================================

# Kullanıcı Kontrolü
CURRENT_USER=$(logname)
USER_HOME="/home/$CURRENT_USER"

echo "----------------------------------------------------------"
echo "SIRAMATIK KIOSK KURULUMU BAŞLIYOR... (Kullanıcı: $CURRENT_USER)"
echo "----------------------------------------------------------"

# 1. CHROMIUM AYARLARI (Hata balonlarını gizler)
echo "[1/4] Chromium ayarları düzenleniyor..."
RPI_VARS="/etc/chromium.d/00-rpi-vars"
if [ -f "$RPI_VARS" ]; then
    # Eğer daha önce eklenmemişse parametreleri ekle
    if ! grep -q "hide-crash-restore-bubble" "$RPI_VARS"; then
        sudo sed -i 's/"$/ --hide-crash-restore-bubble --noerrdialogs"/' "$RPI_VARS"
        echo "   > Chromium FLAG'leri eklendi."
    else
        echo "   > Chromium FLAG'leri zaten mevcut."
    fi
fi

# Chromium çökme kaydını temizle
if [ -f "$USER_HOME/.config/chromium/Default/Preferences" ]; then
    sed -i 's/"exit_type":"Crashed"/"exit_type":"Normal"/' "$USER_HOME/.config/chromium/Default/Preferences"
    echo "   > Chromium çökme durumu temizlendi."
fi

# 2. MULTITOUCH (EKRAN) AYARLARI
echo "[2/4] Dokunmatik ekran ayarları (Multitouch) yapılıyor..."
RC_XML="$USER_HOME/.config/labwc/rc.xml"
if [ -f "$RC_XML" ]; then
    # mouseEmulation="yes" olan yeri "no" yap
    sed -i 's/mouseEmulation="yes"/mouseEmulation="no"/g' "$RC_XML"
    echo "   > Multitouch aktif edildi (rc.xml)."
else
    echo "   > UYARI: $RC_XML bulunamadı! Lütfen labwc/Wayland kullandığınızdan emin olun."
fi

# 3. YAZICI VE GÜNCELLEME SERVİSLERİ
echo "[3/4] Yazıcı ve Otomatik Güncelleme servisleri kuruluyor..."
# Hem mevcut proje dizinine hem de sizin özel 'apps' dizinine bak
PATHS=(
    "$USER_HOME/apps/KIOSK/printer"
    "$USER_HOME/SIRAMATIK/KIOSK/printer"
    "$USER_HOME/SIRAMATIK/kiosk-print-agent"
)

FOUND_PATH=""
for p in "${PATHS[@]}"; do
    if [ -d "$p" ]; then
        FOUND_PATH="$p"
        break
    fi
done

if [ -n "$FOUND_PATH" ]; then
    echo "   > Servis dosyaları bulundu: $FOUND_PATH"
    # Servis dosyalarını /etc/systemd/system/ dizinine kopyala
    sudo cp "$FOUND_PATH"/*.service /etc/systemd/system/
    
    # Servisleri yenile ve aktif et
    sudo systemctl daemon-reload
    
    # Bulunan tüm servisleri aktif etmeyi dene
    for service_file in "$FOUND_PATH"/*.service; do
        service_name=$(basename "$service_file")
        sudo systemctl enable "$service_name"
        echo "   > $service_name aktif edildi."
    done
else
    echo "   > HATA: Servis dosyaları bulunamadı! ~/apps/KIOSK/printer veya SIRAMATIK/KIOSK/printer yolunu kontrol edin."
fi


# 4. YETKİLER VE DOSYA İZİNLERİ
echo "[4/4] Dosya izinleri düzenleniyor..."
if [ -d "$USER_HOME/apps/KIOSK" ]; then
    chmod +x "$USER_HOME/apps/KIOSK/guncellemeler/"*.sh 2>/dev/null
    chmod +x "$USER_HOME/apps/KIOSK/printer/"*.sh 2>/dev/null
    chmod +x "$USER_HOME/apps/KIOSK/ayarlamalar/"*.sh 2>/dev/null
    echo "   > apps/KIOSK script dosyalarına yürütme yetkisi verildi."
fi
if [ -d "$USER_HOME/SIRAMATIK" ]; then
    chmod +x "$USER_HOME/SIRAMATIK/KIOSK/guncellemeler/"*.sh 2>/dev/null
    chmod +x "$USER_HOME/SIRAMATIK/KIOSK/printer/"*.sh 2>/dev/null
    chmod +x "$USER_HOME/SIRAMATIK/KIOSK/ayarlamalar/"*.sh 2>/dev/null
    chmod +x "$USER_HOME/SIRAMATIK/kiosk-print-agent/"*.sh 2>/dev/null
    echo "   > SIRAMATIK/ (geliştirme kopyası) script izinleri verildi."
fi

echo "----------------------------------------------------------"
echo "KURULUM TAMAMLANDI!"
echo "Değişikliklerin devreye girmesi için sistemi yeniden başlatın:"
echo "sudo reboot"
echo "----------------------------------------------------------"
