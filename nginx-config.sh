#!/bin/bash

# URL ke raw file di GitHub
FILE_URL1="https://raw.githubusercontent.com/wafconf/myconf/main/block-user-agent.conf"
FILE_URL2="https://raw.githubusercontent.com/wafconf/myconf/main/bad-referrer.conf"

# Lokasi di mana file akan disimpan
DESTINATION1="/etc/nginx/block-user-agent.conf"
DESTINATION2="/etc/nginx/bad-referrer.conf"

# Lokasi file konfigurasi nginx
NGINX_CONF="/etc/nginx/nginx.conf"

# Memberikan izin eksekusi kepada skrip ini
chmod +x "$0"

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

# Mencari blok 'http' untuk memasukkan konfigurasi map sebelumnya
HTTP_BLOCK_START_LINE=$(grep -n "^http {" $NGINX_CONF | cut -d : -f 1)

# Menambahkan map block untuk bad bots jika belum ada
if ! grep -q "map \$http_user_agent \$bad_bot" $NGINX_CONF; then
    sed -i "${HTTP_BLOCK_START_LINE}i\\\nmap \$http_user_agent \$bad_bot {\n    default 0;\n    include /etc/nginx/block-user-agent.conf;\n}\n" $NGINX_CONF
fi

# Menambahkan map block untuk bad referers jika belum ada
if ! grep -q "map \$http_referer \$bad_referer" $NGINX_CONF; then
    sed -i "${HTTP_BLOCK_START_LINE}i\\\nmap \$http_referer \$bad_referer {\n    default 0;\n    include /etc/nginx/bad-referrer.conf;\n}\n" $NGINX_CONF
fi

# Memeriksa dan mengulang konfigurasi nginx untuk memastikan tidak ada kesalahan
nginx -t && systemctl reload nginx
echo "Nginx configuration has been updated and reloaded."
