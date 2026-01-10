#!/bin/bash

# ==========================================================================
# ADR's GLPI installation script - AL10
# ==========================================================================



# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="GLPI"

# --- LOGGING ---
LOGPATH="/tmp/${SOLUTION}_install_$(date +%s).log"

function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# --- LANGUAGE ---
CONFIG_FILE="$HOME/.config/adr/config"
LOCALES_DIR="$HOME/.config/adr/locales"

# Load language setting from ADR config
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  LANG_CODE="en"  # Default to 'en' if config file doesn't exist
fi

# Ensure the correct locale is sourced
if [[ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ]]; then
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
else
  info_msg "Locale $LANG_CODE not found, falling back to English."
  source "$LOCALES_DIR/en/messages.sh"
fi


# === GLOBAL VARIABLES ===
PORT=62300
TMP_DIR="/tmp"
INSTALL_DIR="/var/www/html/"
DB_NAME="glpi"
DB_USER="glpi"
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
# --- [1/5] INSTALLING PREREQUISITES ---
info_msg "[1/5] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release
sudo dnf install -y wget tar unzip net-tools bzip2 policycoreutils-python-utils httpd mod_ssl
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm
sudo dnf module reset php -y && sudo dnf module enable php:remi-8.5 -y 
sudo dnf install -y php php-{mbstring,mysqli,xml,cli,ldap,openssl,xmlrpc,pecl-apcu,zip,curl,gd,json,session,imap,intl,zlib,redis}

} >>"$LOGPATH" 2>&1



# --- [2/5] INSTALLING MARIADB ---
info_msg "[2/5] ${MSG_INSTALL_MARIADB}"
{
  sudo dnf install -y mariadb-server
  sudo systemctl enable --now mariadb
  sleep 5

  sudo mysql <<SQL
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Disable remote root login
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Apply changes
FLUSH PRIVILEGES;
SQL

# create GLPI DB creds
sudo mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE OR REPLACE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${GLPI_DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF


} >>"$LOGPATH" 2>&1




# --- [3/5] INSTALLING GLPI ---
info_msg "[3/5] ${MSG_INSTALL_SOLUTION}"
{

# Get version 
version=$(curl -fsSL https://api.github.com/repos/glpi-project/glpi/releases/latest \
   | grep '"tag_name"' \
   | cut -d '"' -f4 \
   | sed 's/^v//')

 if [ -z "$version" ]; then
   info_msg "${MSG_ERR_VERSION}"
   exit 1
 fi

info_msg "${MSG_VERSION_DETECTED}: v${version}"


# Download
wget -P "$TMP_DIR" "https://github.com/glpi-project/glpi/releases/download/${version}/glpi-${version}.tgz"


# Installing 
#mkdir -p "${INSTALL_DIR}"
sudo tar -xzf "$TMP_DIR/glpi-${version}.tgz" -C "${INSTALL_DIR}"
sudo php /var/www/html/glpi/bin/console db:install \
  --db-host=localhost \
  --db-name="$DB_NAME" \
  --db-user="$DB_USER" \
  --db-password="$GLPI_DB_PASS" \
  --no-interaction \
  --lang=pt_PT
  
} >>"$LOGPATH" 2>&1


# --- [4/5] INSTALLING APACHE ---
info_msg "[4/5] ${MSG_INSTALL_APACHE}"
{
  sudo dnf install -y httpd
  sudo systemctl enable --now httpd
  
  # File
  sudo tee /etc/httpd/conf.d/glpi.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerName ${SERVER_IP}
    ServerAlias ${ACCESS_URL}
    DocumentRoot /var/www/html/glpi/public

    <Directory /var/www/html/glpi/public>
        AllowOverride All
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>

    ErrorLog /var/log/httpd/glpi_error.log
    CustomLog /var/log/httpd/glpi_access.log combined
</VirtualHost>
EOF
  # Permissions
  sudo chown -R apache:apache "$INSTALL_DIR"
  sudo chmod -R 755 "$INSTALL_DIR"
  sudo rm -f "$INSTALL_DIR/install/install.php"
  
  # PHP
  sudo cp /etc/php.ini /etc/php.ini.bak
  sudo sed -i 's/^session.cookie_httponly =.*/session.cookie_httponly = 1/' /etc/php.ini
  sudo systemctl restart php-fpm
  
  # SElinux
  if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    sudo restorecon -Rv "$INSTALL_DIR"
    sudo setsebool -P httpd_can_sendmail 1
    sudo setsebool -P httpd_can_network_connect 1
    sudo setsebool -P httpd_can_network_connect_db 1
    sudo setsebool -P httpd_mod_auth_ntlm_winbind 1
    sudo setsebool -P allow_httpd_mod_auth_ntlm_winbind 1
  else
   # do nothing
  fi
  
  # Apache restart 
  sudo systemctl restart httpd
  
} >>"$LOGPATH" 2>&1


# --- [5/5] ADJUSTING FIREWALL ---
info_msg "[5/5] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --permanent --add-port=${PORT}/tcp
  sudo firewall-cmd --reload
fi
} >>"$LOGPATH" 2>&1

# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}-${VERSION}"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_DB_NAME}${DB_NAME}"
info_msg " ${MSG_DB_USER}${DB_USER}"
info_msg " ${MSG_DB_PASS}${DB_PASS}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
