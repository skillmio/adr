#!/bin/bash

# ==========================================================================
# ADR's Wordpress installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="Wordpress"

# --- LOGGING ---
LOGPATH="/tmp/${SOLUTION}_install_$(date +%s).log"

function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# --- LANGUAGE ---
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

# === GLOBAL VARIABLES ===
TMP_DIR="/tmp"
INSTALL_DIR="/var/www/html"
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"
MYSQL_ROOT_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"

# === EXECUTION FLOW ===

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

# --- USER PROMPTS ---
read -p "${MSG_PROMPT_IP} ($(hostname -I | awk '{print $1}')): " SERVER_IP
SERVER_IP=${SERVER_IP:-$(hostname -I | awk '{print $1}')}

read -p "${MSG_PROMPT_URL} ($(hostname -f)): " ACCESS_URL
ACCESS_URL=${ACCESS_URL:-$(hostname -f)}

info_msg "${MSG_USING_IP}: $SERVER_IP"
info_msg "${MSG_USING_URL}: $ACCESS_URL"

echo " --- "
# --- [1/6] INSTALLING PREREQUISITES ---
info_msg "[1/6] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release
sudo dnf install -y wget curl tar policycoreutils-python-utils
} >>"$LOGPATH" 2>&1

# --- [2/6] INSTALLING MARIADB ---
info_msg "[2/6] ${MSG_INSTALL_MARIADB}"
{
  sudo dnf install -y mariadb-server
  sudo systemctl enable --now mariadb

  # use socket auth consistently before setting root password
  sudo mysql -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  sudo mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

  sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
  sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
  sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
  sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
} >>"$LOGPATH" 2>&1

# --- [3/6] INSTALLING APACHE ---
info_msg "[3/6] ${MSG_INSTALL_APACHE}"
{
  sudo dnf install -y httpd
  sudo systemctl enable --now httpd
} >>"$LOGPATH" 2>&1

# --- [4/6] INSTALLING PHP ---
info_msg "[4/6] ${MSG_INSTALL_PHP}"
{
  sudo dnf install -y php php-mysqlnd php-gd php-xml php-mbstring \
                     php-json php-curl php-zip php-intl
  sudo systemctl restart httpd
  php -v
} >>"$LOGPATH" 2>&1

# --- [5/6] INSTALLING WORDPRESS ---
info_msg "[5/6] ${MSG_INSTALL_SOLUTION}"
{
  cd /tmp
  curl -O https://wordpress.org/latest.tar.gz
  tar xzf latest.tar.gz

  sudo mv wordpress ${INSTALL_DIR}/
  restorecon -Rv ${INSTALL_DIR}/wordpress
  sudo chown -R apache:apache ${INSTALL_DIR}/wordpress
  sudo find ${INSTALL_DIR}/wordpress -type d -exec chmod 755 {} \;
  sudo find ${INSTALL_DIR}/wordpress -type f -exec chmod 644 {} \;
  sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

 if [ "$(getenforce 2>/dev/null)" = "Enforcing" ] || \
   [ "$(getenforce 2>/dev/null)" = "Permissive" ]; then
    # After moving and chowning wordpress
   sudo mkdir -p ${INSTALL_DIR}/wordpress/wp-content/uploads
   sudo chown -R apache:apache ${INSTALL_DIR}/wordpress/wp-content
   sudo restorecon -Rv ${INSTALL_DIR}/wordpress
   sudo setsebool -P httpd_can_network_connect_db on
   # Then SELinux for writable dirs
   sudo chcon -R -t httpd_sys_rw_content_t "${INSTALL_DIR}/wordpress/wp-content/uploads"
    # Optionally cache directory if you use caching plugins
   sudo mkdir -p ${INSTALL_DIR}/wordpress/wp-content/cache
   sudo chcon -R -t httpd_sys_rw_content_t "${INSTALL_DIR}/wordpress/wp-content/cache"
   fi

  # Import folder
  sudo tee /etc/httpd/conf.d/wordpress.conf <<EOF
<VirtualHost *:80>
  ServerName ${ACCESS_URL}
  ServerAlias ${SERVER_IP}
  DocumentRoot ${INSTALL_DIR}/wordpress
  <Directory ${INSTALL_DIR}/wordpress>
    AllowOverride All
    Require all granted
  </Directory>
  ErrorLog /var/log/httpd/wordpress_error.log
  CustomLog /var/log/httpd/wordpress_access.log combined
</VirtualHost>
EOF

# Create wp-config
sudo cp /var/www/html/wordpress/wp-config-sample.php \
        /var/www/html/wordpress/wp-config.php

echo "define('DISALLOW_FILE_EDIT', true);" | sudo tee -a ${INSTALL_DIR}/wordpress/wp-config.php

# replace DB values
sudo sed -i "s/database_name_here/${DB_NAME}/"  ${INSTALL_DIR}/wordpress/wp-config.php
sudo sed -i "s/username_here/${DB_USER}/"  ${INSTALL_DIR}/wordpress/wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/"  ${INSTALL_DIR}/wordpress/wp-config.php

sudo chmod 600 ${INSTALL_DIR}/wordpress/wp-config.php


sudo systemctl restart httpd
} >>"$LOGPATH" 2>&1

# --- [6/6] ADJUSTING FIREWALL ---
info_msg "[6/6] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then   # ← set -e safe
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
fi
} >>"$LOGPATH" 2>&1

# --- EXTRA GRAB INSTALLED VERSION ---
WP_VERSION="unknown"
if [[ -f "${INSTALL_DIR}/wordpress/wp-includes/version.php" ]]; then
  WP_VERSION=$(sed -n "s/^[[:space:]]*\$wp_version[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" \
    "${INSTALL_DIR}/wordpress/wp-includes/version.php")
fi

# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}=${WP_VERSION}"
info_msg " ${MSG_INSTALL_PATH}${INSTALL_DIR}/wordpress"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_DB_NAME}${DB_NAME}"
info_msg " ${MSG_DB_USER}${DB_USER}"
info_msg " ${MSG_DB_PASS}${DB_PASS}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
