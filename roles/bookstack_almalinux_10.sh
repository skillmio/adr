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
TIMESTAMP="$(date +%s)"
LOGPATH="/tmp/${SOLUTION}_install_${TIMESTAMP}.log"

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
# START MESSAGE
############################################
echo "=== Starting BookStack Provisioning ==="
echo "Sensitive log file (delete after use): $LOGPATH"

############################################
# PROMPT FOR IP AND DOMAIN
############################################
read -rp "Enter the IP address that will be used to access BookStack [${DEFAULT_IP}]: " SERVER_IP
SERVER_IP="${SERVER_IP:-$DEFAULT_IP}"

read -rp "Enter the URL or Hostname that will be used to access BookStack: " DOMAIN
[ -n "$DOMAIN" ] || error_out "Domain or IP is required"

info_msg "IP has been set to: $SERVER_IP"
info_msg "URL has been set to: $DOMAIN"
echo " --- "

############################################
# [1/4] INSTALLING REQUIRED PACKAGES
############################################
info_msg "[1/4] Installing Required Packages"
{
dnf install -y git nginx mariadb-server \
php php-cli php-fpm php-bcmath php-mbstring php-ldap php-xml php-gd php-mysqlnd php-pecl-zip \
policycoreutils-python-utils
cd "$BOOKSTACK_DIR" 2>/dev/null || true
php bookstack-system-cli download-vendor 2>/dev/null || true
} >>"$LOGPATH" 2>&1

############################################
# [2/4] INSTALLING AND CONFIGURING MARIADB
############################################
info_msg "[2/4] Installing and Configuring MariaDB"
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
# [3/4] INSTALLING AND CONFIGURING BOOKSTACK
############################################
info_msg "[3/4] Installing and Configuring BookStack"
{
cd /var/www
git clone https://source.bookstackapp.com/bookstack.git --branch release --single-branch bookstack

cd "$BOOKSTACK_DIR"
cp .env.example .env
sed -i \
  -e "s|^APP_URL=.*|APP_URL=http://${DOMAIN}|" \
  -e "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" \
  -e "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" \
  -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env

php artisan key:generate --force --no-interaction
php artisan migrate --force --no-interaction

chown -R apache:apache .
chmod -R 755 .
chmod -R 775 storage bootstrap/cache public/uploads
chmod 740 .env
git config core.fileMode false

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
# [4/4] FIREWALL & SELINUX
############################################
info_msg "[4/4] Creating allow rules on the firewall"
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
info_msg "=================================================================="
info_msg " BookStack installation completed (SAVE THIS INFO)"
info_msg "------------------------------------------------------------------"
info_msg " Access via URL: http://${DOMAIN}"
info_msg " Access via IP: http://${SERVER_IP}"
info_msg " User:  Admin"
info_msg " Pass:  password"
info_msg "---"
info_msg " Database name: ${DB_NAME}"
info_msg " DB User: ${DB_USER}"
info_msg " DB Pass: ${DB_PASS}"
info_msg " Sensitive log file (delete after use): $LOGPATH"
info_msg "=================================================================="
info_msg "Based on Dan Brown's - Bookstack for Almalinux 10 Script"

