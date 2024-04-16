#!/bin/bash

# Direktori di mana file konfigurasi Nginx tersimpan
NGINX_SITES_AVAILABLE="/etc/nginx/sites-available"

# Backup direktori sebelum modifikasi
BACKUP_DIR="/etc/nginx/backup-sites-available-$(date +%Y%m%d%H%M)"
cp -r $NGINX_SITES_AVAILABLE $BACKUP_DIR

# Teks yang akan dicari untuk mencegah penambahan berulang
SEARCH_BADAGENT="if (\$badagent) { return 403; }"
SEARCH_BADREFERER="if (\$bad_referer) { return 403; }"

# Menambahkan kondisi 'if' ke setiap file konfigurasi server
for CONFIG in $NGINX_SITES_AVAILABLE/*; do
    # Hanya beroperasi pada file teks
    if [[ -f $CONFIG && -r $CONFIG ]]; then
        # Cek apakah konfigurasi sudah ada
        if ! grep -q "$SEARCH_BADAGENT" $CONFIG; then
            sed -i '/server {/ a \\n    # Custom Conditions for badagent\n    if ($badagent) {\n        return 403;\n    }\n' $CONFIG
        fi
        if ! grep -q "$SEARCH_BADREFERER" $CONFIG; then
            sed -i '/server {/ a \\n    # Custom Conditions for bad_referer\n    if ($bad_referer) {\n        return 403;\n    }\n' $CONFIG
        fi
    fi
done

# Memeriksa dan mengulang konfigurasi nginx untuk memastikan tidak ada kesalahan
nginx -t && systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "Nginx configuration has been updated and reloaded successfully."
else
    echo "Failed to update Nginx configuration."
    # Restore the original configuration files from backup
    echo "Restoring from backup..."
    rm -rf $NGINX_SITES_AVAILABLE
    cp -r $BACKUP_DIR $NGINX_SITES_AVAILABLE
    systemctl reload nginx
    exit 1
fi
