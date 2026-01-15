#!/bin/bash

# ==========================================================================
# ADR's LAMP Stack installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="LAMP"

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
# --- [1/4] INSTALLING PREREQUISITES ---
info_msg "[1/4] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release
dnf config-manager --set-enabled crb #enable codereadybuilder
sudo dnf install -y wget curl tar
} >>"$LOGPATH" 2>&1

# --- [2/4] INSTALLING APACHE ---
info_msg "[2/4] ${MSG_INSTALL_APACHE}"
{
sudo dnf install -y httpd httpd-tools
systemctl enable httpd
systemctl start httpd
systemctl status httpd

} >>"$LOGPATH" 2>&1

# --- [3/4] INSTALLING PHP ---
info_msg "[3/4] ${MSG_INSTALL_PHP}"
{
dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm
dnf module switch-to php:remi-8.4
dnf module install -y php:remi-8.4
systemctl restart httpd 
php -v

# echo "<?php phpinfo() ?>" > /var/www/html/info.php # optional

} >>"$LOGPATH" 2>&1

# --- [4/4] INSTALLING MARIADB ---
info_msg "[4/4] ${MSG_INSTALL_MARIADB}"
{
dnf install -y dnf install mariadb-server mariadb
systemctl enable mariadb
systemctl start mariadb
systemctl status mariadb

# Secure MariaDB
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DELETE FROM mysql.user WHERE User='';"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "DROP DATABASE IF EXISTS test;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "FLUSH PRIVILEGES;"
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "SHOW DATABASES;"

} >>"$LOGPATH" 2>&1


# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
