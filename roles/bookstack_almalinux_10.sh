#!/usr/bin/env bash
# ==========================================================================
# ADR Role: BookStack
# Supported OS: AlmaLinux 10 / RHEL 10
# ==========================================================================

set -e

############################################
# SOLUTION & LOGGING
############################################
SOLUTION="bookstack"
ROLE_NAME="bookstack"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOGPATH="/var/log/adr_${ROLE_NAME}_${TIMESTAMP}.log"

info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

error_out() {
  echo "ERROR: $1" | tee -a "$LOGPATH" >&2
  exit 1
}

############################################
# GLOBAL VARIABLES
############################################
BOOKSTACK_DIR="/var/www/bookstack"
DB_NAME="bookstack"
DB_USER="bookstack"
DB_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)"
SCRIPT_USER="${SUDO_USER:-$USER}"
DEFAULT_IP="$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -n1)"
SERVER_IP=""
DOMAIN=""

############################################
# PRE-CHECKS
############################################
info_msg "[1/11] Pre-installation checks"
[ "$EUID" -eq 0 ] || error_out "This role must be run as root"

if [ -d /etc/nginx/conf.d ] && [ "$(ls -A /etc/nginx/conf.d)" ]; then
  error_out "Existing nginx configuration detected – fresh system required"
fi

if [ -d /var/lib/mysql ]; then
  error_out "Existing MariaDB/MySQL data detected – aborting"
fi

############################################
# NETWORK INPUT
############################################
info_msg "[2/11] Network configuration"
read -rp "Enter server IP [${DEFAULT_IP}]: " SERVER_IP
SERVER_IP="${SERVER_IP:-$DEFAULT_IP}"

read -rp "Enter domain or FQDN for BookStack (or IP): " DOMAIN
[ -n "$DOMAIN" ] || error_out "Domain or IP is required"

info_msg "Using IP     : ${SERVER_IP}"
info_msg "Using domain : ${DOMAIN}"

############################################
# PACKAGE INSTALLATION
############################################
info_msg "[3/11] Installing packages"
{
dnf install -y \
  git nginx mariadb-server \
  php php-cli php-fpm php-bcmath php-mbstring php-ldap \
  php-xml php-gd php-mysqlnd php-pecl-zip \
  policycoreutils-python-utils
} >>"$LOGPATH" 2>&1

############################################
# DATABASE SETUP
############################################
info_msg "[4/11] Database setup"
{
systemctl enable --now mariadb
sleep 3

mysql -u root <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
} >>"$LOGPATH" 2>&1

############################################
# DOWNLOAD BOOKSTACK
############################################
info_msg "[5/11] Downloading BookStack"
{
cd /var/www
git clone https://source.bookstackapp.com/bookstack.git \
  --branch release --single-branch bookstack
} >>"$LOGPATH" 2>&1

############################################
# PHP DEPENDENCIES
############################################
info_msg "[6/11] Installing PHP dependencies"
{
cd "$BOOKSTACK_DIR"
php bookstack-system-cli download-vendor
} >>"$LOGPATH" 2>&1

############################################
# ENV CONFIGURATION
############################################
info_msg "[7/11] Configuring environment"
{
cd "$BOOKSTACK_DIR"
cp .env.example .env
sed -i \
  -e "s|^APP_URL=.*|APP_URL=http://${DOMAIN}|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env
php artisan key:generate --force --no-interaction
} >>"$LOGPATH" 2>&1

############################################
# DATABASE MIGRATION
############################################
info_msg "[8/11] Database migration"
{
cd "$BOOKSTACK_DIR"
php artisan migrate --force --no-interaction
} >>"$LOGPATH" 2>&1

############################################
# PERMISSIONS
############################################
info_msg "[9/11] Permissions & ownership"
{
cd "$BOOKSTACK_DIR"
chown -R apache:apache .
chmod -R 755 .
chmod -R 775 storage bootstrap/cache public/uploads
chmod 740 .env
git config core.fileMode false
} >>"$LOGPATH" 2>&1

############################################
# NGINX CONFIGURATION
############################################
info_msg "[10/11] Nginx configuration"
{
cat >/etc/nginx/conf.d/bookstack.conf <<EOF
server {
  listen 80;
  server_name ${DOMAIN} ${SERVER_IP};

  root ${BOOKSTACK_DIR}/public;
  index index.php index.html;

  location / {
    try_files \$uri \$uri/ /index.php?\$query_string;
  }

  location ~ \.php\$ {
    include fastcgi.conf;
    fastcgi_pass php-fpm;
  }
}
EOF
systemctl enable --now php-fpm nginx
} >>"$LOGPATH" 2>&1

############################################
# FIREWALL & SELINUX
############################################
info_msg "[11/11] Firewall & SELinux"
{
firewall-cmd --permanent --add-service=http
firewall-cmd --reload

semanage fcontext -a -t httpd_sys_content_t "${BOOKSTACK_DIR}(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/storage(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/bootstrap/cache(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/public/uploads(/.*)?"

restorecon -R "$BOOKSTACK_DIR"
} >>"$LOGPATH" 2>&1

############################################
# SAVE THIS INFO
############################################
info_msg ""
info_msg "================= SAVE THIS INFO ================="
info_msg "Application : BookStack"
info_msg "URL         : http://${DOMAIN}/"
info_msg "Install dir : ${BOOKSTACK_DIR}"
info_msg " ${MSG_USER_LOGIN} admin@admin.com"
info_msg " ${MSG_USER_PASS} password"
info_msg ""
info_msg "DB name     : ${DB_NAME}"
info_msg "DB user     : ${DB_USER}"
info_msg "DB password : ${DB_PASS}"
info_msg "Log file    : ${LOGPATH}"
info_msg ""
info_msg "Based on Dan Brown's - Bookstack for Almalinux 10 Script"
info_msg "=================================================="
