#!/usr/bin/env bash
# ==========================================================================
# ADR Role: Nextcloud
# Supported OS: AlmaLinux 10 / RHEL 10
# ==========================================================================

set -e
clear

############################################
# SOLUTION & LOGGING
############################################
SOLUTION="nextcloud"
LOGPATH="/tmp/${SOLUTION}_install_$(date +%s).log"

info_msg() {
  echo "$1" | tee -a "$LOG_FILE"
}

error_out() {
  echo "ERROR: $1" | tee -a "$LOG_FILE" >&2
  exit 1
}

############################################
# LANGUAGE
############################################

CONFIG_FILE="$HOME/.config/adr/config"
LOCALES_DIR="$HOME/.config/adr/locales"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  LANG_CODE="en"
fi

if [[ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ]]; then
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
else
  info_msg "Locale $LANG_CODE not found, falling back to English."
  source "$LOCALES_DIR/en/messages.sh"
fi


############################################
# GLOBAL VARIABLES
############################################
NC_DB_NAME="nextcloud"
NC_DB_USER="nextcloud"
MYSQL_ROOT_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"
NC_DB_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"


############################################
# START MESSAGE
############################################
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

############################################
# PROMPT FOR IP / DOMAIN
############################################
read -p "${MSG_PROMPT_IP} ($(hostname -I | awk '{print $1}')): " SERVER_IP
SERVER_IP=${SERVER_IP:-$(hostname -I | awk '{print $1}')}

read -p "${MSG_PROMPT_URL} ($(hostname -f)): " ACCESS_URL
ACCESS_URL=${ACCESS_URL:-$(hostname -f)}

info_msg "${MSG_USING_IP}: $SERVER_IP"
info_msg "${MSG_USING_URL}: $ACCESS_URL"
echo " --- "

############################################
# [1/4] INSTALLING PACKAGES
############################################
info_msg "[1/4] Installing Required Packages"
{
dnf install -y epel-release unzip wget curl httpd httpd-tools mariadb mariadb-server mariadb-devel \
  setroubleshoot-server policycoreutils-python-utils \
  php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-json php-mbstring \
  php-curl php-xml php-pear php-bcmath php-opcache php-intl php-ldap
systemctl enable --now httpd mariadb php-fpm
} >>"$LOG_FILE" 2>&1

############################################
# [2/4] CONFIGURE DATABASE
############################################
info_msg "[2/4] Configuring MariaDB and Nextcloud Database"
{

# Secure MariaDB and create DB
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE ${NC_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE OR REPLACE USER '${NC_DB_USER}'@'localhost' IDENTIFIED BY '${NC_DB_PASS}';
GRANT ALL PRIVILEGES ON ${NC_DB_NAME}.* TO '${NC_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Tune MariaDB
tee /etc/my.cnf.d/nextcloud.cnf > /dev/null <<EOF
[mysqld]
innodb_buffer_pool_size = 128M
innodb_log_file_size = 32M
query_cache_type = 1
query_cache_size = 16M
tmp_table_size = 32M
max_heap_table_size = 32M
max_connections = 500
thread_cache_size = 50
open_files_limit = 65535
table_definition_cache = 4096
table_open_cache = 4096
EOF
systemctl restart mariadb
} >>"$LOG_FILE" 2>&1

############################################
# [3/4] INSTALL NEXTCLOUD
############################################
info_msg "[3/4] Installing Nextcloud"
{
cd /tmp
mkdir -p nextcloud && cd nextcloud
wget -q https://download.nextcloud.com/server/releases/latest.zip -O latest.zip
unzip -q latest.zip -d /var/www/html/
rm -f latest.zip

mkdir -p /var/www/nextcloud-data
chown -R apache:apache /var/www/html/nextcloud /var/www/nextcloud-data
find /var/www/html/nextcloud/ -type d -exec chmod 755 {} \;
find /var/www/html/nextcloud/ -type f -exec chmod 644 {} \;
chmod +x /var/www/html/nextcloud/occ
chmod 775 /var/www/html/nextcloud/config /var/www/html/nextcloud/apps /var/www/nextcloud-data

# Apache config
tee /etc/httpd/conf.d/nextcloud.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ${DOMAIN}
    DocumentRoot /var/www/html/nextcloud

    <Directory /var/www/html/nextcloud>
        Options +FollowSymlinks
        AllowOverride All
        Require all granted
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
    </Directory>

    # Security headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "DENY"
    Header always set X-XSS-Protection "1; mode=block"

    ErrorLog /var/log/httpd/nextcloud_error.log
    CustomLog /var/log/httpd/nextcloud_access.log combined
</VirtualHost>
EOF

httpd -t && systemctl restart httpd

# PHP tuning
cp /etc/php.ini /etc/php.ini.bak
sed -i 's/^memory_limit = .*/memory_limit = 512M/' /etc/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 512M/' /etc/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 512M/' /etc/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' /etc/php.ini
sed -i 's/^max_input_time = .*/max_input_time = 300/' /etc/php.ini
sed -i 's@^;date.timezone =@date.timezone = "UTC"@' /etc/php.ini

# OPCache
cp /etc/php.d/10-opcache.ini /etc/php.d/10-opcache.ini.bak
sed -i 's/^;opcache.enable=.*/opcache.enable=1/' /etc/php.d/10-opcache.ini
sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=128/' /etc/php.d/10-opcache.ini
sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=10/' /etc/php.d/10-opcache.ini
sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=4000/' /etc/php.d/10-opcache.ini
sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=2/' /etc/php.d/10-opcache.ini
echo "opcache.fast_shutdown=1" >> /etc/php.d/10-opcache.ini

# SELinux
semanage fcontext -a -t httpd_exec_t "/var/www/html/nextcloud/occ"
semanage fcontext -a -t httpd_config_t "/var/www/html/nextcloud/config(/.*)?"
semanage fcontext -a -t httpd_config_t "/var/www/nextcloud-data(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/data(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/config(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/nextcloud/apps(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/nextcloud-data(/.*)?"
restorecon -Rv /var/www/html/nextcloud/ /var/www/nextcloud-data/
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_execmem 1
setsebool -P httpd_unified 1
systemctl restart php-fpm httpd
} >>"$LOG_FILE" 2>&1

############################################
# [4/4] FIREWALL RULES
############################################
info_msg "[4/4] Adjusting Firewall (HTTP/HTTPS)"
firewall-cmd --permanent --add-service={http,https}
firewall-cmd --reload

############################################
# SAVE THIS INFO
############################################
info_msg ""
info_msg "=================================================================="
info_msg " Nextcloud installation completed (SAVE THIS INFO)"
info_msg "------------------------------------------------------------------"
info_msg " Access via URL: http://${DOMAIN}"
info_msg " Access via IP: http://${SERVER_IP}"
info_msg " MariaDB root password: ${MYSQL_ROOT_PASS}"
info_msg " Nextcloud DB user: ${NC_DB_USER}"
info_msg " Nextcloud DB password: ${NC_DB_PASS}"
info_msg " Database name: ${NC_DB_NAME}"
info_msg " Sensitive log file (delete after use): $LOG_FILE"
info_msg "=================================================================="
