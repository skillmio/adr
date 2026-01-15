#!/bin/bash

# ==========================================================================
# ADR's Wordpress Stack installation script - AL10
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
dnf config-manager --set-enabled crb #enable codereadybuilder
sudo dnf install -y wget curl tar
} >>"$LOGPATH" 2>&1

# --- [2/6] INSTALLING APACHE ---
info_msg "[2/6] ${MSG_INSTALL_APACHE}"
{
sudo dnf install -y httpd httpd-tools
systemctl enable httpd
systemctl start httpd
systemctl status httpd

} >>"$LOGPATH" 2>&1

# --- [3/6] INSTALLING PHP ---
info_msg "[3/6] ${MSG_INSTALL_PHP}"
{
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm
dnf module -y switch-to php:remi-8.4
dnf module install -y php:remi-8.4
systemctl restart httpd 
php -v

# echo "<?php phpinfo() ?>" > /var/www/html/info.php # optional

} >>"$LOGPATH" 2>&1

# --- [4/6] INSTALLING MARIADB ---
info_msg "[4/6] ${MSG_INSTALL_MARIADB}"
{
dnf install -y dnf install mariadb-server mariadb
systemctl enable mariadb
systemctl start mariadb
systemctl status mariadb

# use socket auth consistently before setting root password
sudo mysql -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "SHOW DATABASES;"

} >>"$LOGPATH" 2>&1


# --- [5/6] INSTALLING WORDPRESS ---
info_msg "[5/6] ${MSG_INSTALL_SOLUTION}"
{

#Download and copy
cd "${TMP_DIR}"
curl https://wordpress.org/latest.tar.gz --output wordpress.tar.gz
tar xf wordpress.tar.gz
cp -r wordpress /var/www/html

#Permissions
chown -R apache:apache /var/www/html/wordpress

if [ "$(getenforce 2>/dev/null)" = "Enforcing" ] || \
   [ "$(getenforce 2>/dev/null)" = "Permissive" ]; then
chcon -t httpd_sys_rw_content_t /var/www/html/wordpress -R
setsebool -P httpd_can_network_connect true
fi

#Import wordpress code block
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

sudo systemctl restart httpd
} >>"$LOGPATH" 2>&1


# --- [6/6] ADJUSTING FIREWALL ---
info_msg "[6/6] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then   # ← set -e safe
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --permanent --add-port=${PORT}/tcp
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
