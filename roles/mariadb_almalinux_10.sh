#!/bin/bash

# ==========================================================================
# ADR's MySQL installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="MariaDB"


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
PORT=3306
TMP_DIR="/tmp"
MYSQL_ROOT_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"
DB_USER="root"


# === EXECUTION FLOW ===

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

# --- USER PROMPTS ---
read -p "${MSG_PROMPT_IP} ($(hostname -I | awk '{print $1}')): " SERVER_IP
SERVER_IP=${SERVER_IP:-$(hostname -I | awk '{print $1}')}

info_msg "${MSG_USING_IP}: $SERVER_IP"

echo " --- "
echo ""

# --- [1/6] INSTALLING PREREQUISITES ---
info_msg "[1/6] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release wget 
sudo dnf install -y https://rpms.remirepo.net/enterprise/remi-release-10.rpm


} >>"$LOGPATH" 2>&1


# --- [2/6] INSTALLING MARIADB ---
info_msg "[2/6] ${MSG_INSTALL_MARIADB}"
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
  sudo dnf install -y php-fedora-autoloader
  sudo dnf --enablerepo=remi install phpMyAdmin -y
  sudo systemctl restart httpd
} >>"$LOGPATH" 2>&1


# --- [6/6] INSTALLING PHPMYADMIN ---
info_msg "[5/6] ${MSG_INSTALL_PHPMYADMIN}"
{
  sudo dnf install php-json php-mbstring php-zip php-gd php-xml php-curl -y
  sudo dnf install -y php-fedora-autoloader
  sudo dnf --enablerepo=remi install phpMyAdmin -y
  sudo sed -i 's/^[[:space:]]*Require[[:space:]]\+local/Require all granted/' /etc/httpd/conf.d/phpMyAdmin.conf
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
MARIADB_VERSION=$(rpm -q mariadb-server --qf '%{VERSION}-%{RELEASE}\n')



# === SAVE THIS INFO ===
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}-${MARIADB_VERSION}"
info_msg " ${MSG_IP}${SERVER_IP}/phpmyadmin"
info_msg " ${MSG_USER_LOGIN}${DB_USER}"
info_msg " ${MSG_USER_PASS}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
