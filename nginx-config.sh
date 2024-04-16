#!/bin/bash

# URL ke raw file di GitHub
FILE_URL1="https://raw.githubusercontent.com/wafconf/myconf/main/block-user-agent.rules"
FILE_URL2="https://raw.githubusercontent.com/wafconf/myconf/main/block-bad-referrer.rules"

# Lokasi di mana file akan disimpan
DESTINATION1="/etc/nginx/block-user-agent.rules"
DESTINATION2="/etc/nginx/block-bad-referrer.rules"

# Lokasi file konfigurasi nginx
NGINX_CONF="/etc/nginx/nginx.conf"

# Cek apakah script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Script ini harus dijalankan sebagai root."
    exit 1
fi

# Mengunduh file konfigurasi
curl -o $DESTINATION1 $FILE_URL1
echo "block-user-agent.rules has been downloaded and saved to $DESTINATION1."
curl -o $DESTINATION2 $FILE_URL2
echo "block0bad-referrer.rules has been downloaded and saved to $DESTINATION2."

# Backup file konfigurasi nginx sebelum modifikasi
cp $NGINX_CONF "${NGINX_CONF}.bak"

# Menambahkan map block ke nginx.conf dalam blok http
sed -i '/http {/ a \\n    # Map blocks\n  include /etc/nginx/block-user-agent.rules;\n  \n\n  include /etc/nginx/block-bad-referrer.rules;\n \n' $NGINX_CONF

# Memeriksa dan mengulang konfigurasi nginx untuk memastikan tidak ada kesalahan
nginx -t && systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "Nginx configuration has been updated and reloaded."
else
    echo "Failed to update Nginx configuration."
    # Restore the original configuration file
    mv "${NGINX_CONF}.bak" $NGINX_CONF
    exit 1
fi
