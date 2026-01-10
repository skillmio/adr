#!/bin/bash

# ==========================================================================
# ADR's Bookstack installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="Bookstack"

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
PORT=1005
DB_NAME="bookstack"
DB_USER="bookstack"
DB_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"
INSTALL_DIR="/var/www/bookstack"


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
	dnf install -y git php php-cli \
	php-bcmath php-fpm php-mbstring php-ldap php-xml php-gd php-mysqlnd php-pecl-zip
	
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

} >>"$LOGPATH" 2>&1

# --- [3/5] INSTALLING BOOKSTACK ---
info_msg "[3/5] ${MSG_INSTALL_SOLUTION}"
{

# Setup database
  mysql -u root --execute="CREATE DATABASE ${DB_NAME};"
  mysql -u root --execute="CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
  mysql -u root --execute="GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';FLUSH PRIVILEGES;"


# Download
  cd /var/www || exit
  git clone https://source.bookstackapp.com/bookstack.git --branch release --single-branch bookstack


# Install BookStack composer dependencies
  cd "$INSTALL_DIR" || exit
  php bookstack-system-cli download-vendor


# Copy and update BookStack environment variables
  cd "$INSTALL_DIR" || exit
  cp .env.example .env
  sed -i.bak "s@APP_URL=.*\$@APP_URL=http://$DOMAIN@" .env
  sed -i.bak 's/DB_DATABASE=.*$/DB_DATABASE=bookstack/' .env
  sed -i.bak 's/DB_USERNAME=.*$/DB_USERNAME=bookstack/' .env
  sed -i.bak "s/DB_PASSWORD=.*\$/DB_PASSWORD=$DB_PASS/" .env
  # Generate the application key
  php artisan key:generate --no-interaction --force


# Run the BookStack database migrations for the first time
  cd "$INSTALL_DIR" || exit
  php artisan migrate --no-interaction --force

# Set file and folder permissions
  cd "$BOOKSTACK_DIR" || exit
  chown -R "$SCRIPT_USER":apache ./
  chmod -R 755 ./
  chmod -R 775 bootstrap/cache public/uploads storage
  chmod 740 .env

  # Tell git to ignore permission changes
  git config core.fileMode false



} >>"$LOGPATH" 2>&1



# --- [4/5] INSTALLING NGNIX ---
info_msg "[4/5] ${MSG_INSTALL_NGINX}"
{
  sudo dnf install -y nginx
  
# Setup nginx with the needed config
 cat >/etc/nginx/conf.d/bookstack.conf <<EOL
server {
  listen 80;
  listen [::]:80;

  server_name ${SERVER_IP} ${ACCESS_URL};

  root /var/www/bookstack/public;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
  }
  
  location ~ \.php$ {
    include fastcgi.conf;
    fastcgi_pass php-fpm;
  }
}

EOL

  systemctl enable --now nginx.service
  # Restart nginx to load new config
  systemctl restart nginx
  # Ensure php-fpm service has started
  systemctl enable --now php-fpm.service
  
  # Configure SELinux
  # Set the httpd_sys_content_t type on all bookstack files
  semanage fcontext -a -t httpd_sys_content_t    '/var/www/bookstack(/.*)?'
  # Set the httpd_sys_rw_content_t type on all directories that will need need read-write access
  semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/bookstack/storage(/.*)?'
  semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/bookstack/bootstrap/cache(/.*)?'
  semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/bookstack/public/uploads(/.*)?'
  # Apply the changes
  restorecon -R /var/www/bookstack
  
 
} >>"$LOGPATH" 2>&1

# --- [5/5] ADJUSTING FIREWALL ---
info_msg "[5/5] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then   
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --reload
fi
} >>"$LOGPATH" 2>&1




# --- EXTRA GRAB INSTALLED VERSION ---
xversion=$(php artisan bookstack:version)


# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}=${XVERSION}"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_USER_LOGIN} admin@admin.com"
info_msg " ${MSG_USER_PASS} password"
info_msg "---"
info_msg " ${MSG_DB_NAME}${DB_NAME}"
info_msg " ${MSG_DB_USER}${DB_USER}"
info_msg " ${MSG_DB_PASS}${DB_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
