#!/bin/bash

# URL ke raw file di GitHub
FILE_URL1="https://raw.githubusercontent.com/username/repo/main/path/to/block-user-agent.conf"
FILE_URL2="https://raw.githubusercontent.com/username/repo/main/path/to/bad-referrer.conf"

# Lokasi di mana file akan disimpan
DESTINATION1="/etc/nginx/block-user-agent.conf"
DESTINATION2="/etc/nginx/bad-referrer.conf"

# Lokasi file konfigurasi nginx
NGINX_CONF="/etc/nginx/nginx.conf"

# Cek apakah script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    echo "Script ini harus dijalankan sebagai root."
    exit 1
fi

# Mengunduh file konfigurasi
curl -o $DESTINATION1 $FILE_URL1
echo "block-user-agent.conf has been downloaded and saved to $DESTINATION1."
curl -o $DESTINATION2 $FILE_URL2
echo "bad-referrer.conf has been downloaded and saved to $DESTINATION2."

# Backup file konfigurasi nginx sebelum modifikasi
cp $NGINX_CONF "${NGINX_CONF}.bak"

# Menambahkan map block ke nginx.conf dalam blok http
sed -i '/http {/ a \\n    # Map blocks\n    map $http_user_agent $bad_bot {\n        default 0;\n        include /etc/nginx/block-user-agent.conf;\n    }\n\n    map $http_referer $bad_referer {\n        default 0;\n        include /etc/nginx/bad-referrer.conf;\n    }\n' $NGINX_CONF

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
