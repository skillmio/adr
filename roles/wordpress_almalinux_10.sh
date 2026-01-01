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

# === INSTALLATION STEPS ===

# --- [1/6] INSTALLING PREREQUISITES ---
info_msg "[1/6] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release
sudo dnf install -y wget tar 
} >>"$LOGPATH" 2>&1

# --- [2/6] INSTALLING MARIADB ---
info_msg "[2/6] ${MSG_INSTALL_MARIADB}"
{
  sudo dnf install -y mariadb-server
  sudo systemctl enable --now mariadb

  mysql -u root -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mysql -u root -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -u root -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost'; FLUSH PRIVILEGES;"

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
  sudo chown -R apache:apache ${INSTALL_DIR}/wordpress
  sudo find ${INSTALL_DIR}/wordpress -type d -exec chmod 755 {} \;
  sudo find ${INSTALL_DIR}/wordpress -type f -exec chmod 644 {} \;

  sudo sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf
  sudo systemctl restart httpd

  sudo dnf install -y policycoreutils-python-utils
  sudo chcon -R -t httpd_sys_rw_content_t ${INSTALL_DIR}/wordpress
  sudo setsebool -P httpd_can_network_connect_db on

  sudo tee /etc/httpd/conf.d/wordpress.conf <<EOF
<VirtualHost *:80>
  ServerName ${SERVER_IP}
  ServerAlias ${ACCESS_URL}
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
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
} >>"$LOGPATH" 2>&1


# --- EXTRA GRAB INSTALLED VERSION ---
WP_VERSION=$(sed -n "s/^[[:space:]]*\$wp_version[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" \
  "${INSTALL_DIR}/wordpress/wp-includes/version.php")



# === SAVE THIS INFO ===
info_msg "======================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "---------------------------------------"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_INSTALL_PATH}${INSTALL_DIR}/wordpress"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}:${WP_VERSION}"
info_msg " ${MSG_DB_NAME}${DB_NAME}"
info_msg " ${MSG_DB_USER}${DB_USER}"
info_msg " ${MSG_DB_PASS}${DB_PASS}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "======================================="
