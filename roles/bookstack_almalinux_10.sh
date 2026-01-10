#!/usr/bin/env bash
# ADR Role: BookStack
# Supported OS: AlmaLinux 10 / RHEL 10

set -e

############################################
# SOLUTION
############################################
SOLUTION="BookStack Documentation Platform"

############################################
# ADR BASE & LOGGING
############################################
ROLE_NAME="bookstack"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
LOGPATH="/var/log/adr_${ROLE_NAME}_${TIMESTAMP}.log"

info_msg() {
  echo -e "$1" | tee -a "$LOGPATH"
}

error_out() {
  echo -e "ERROR: $1" | tee -a "$LOGPATH" >&2
  exit 1
}

############################################
# LANGUAGE (ADR standard – placeholder)
############################################
# shellcheck disable=SC1091
[ -f /etc/adr/config ] && source /etc/adr/config
LANGUAGE="${ADR_LANG:-EN}"

############################################
# GLOBAL VARIABLES
############################################
SCRIPT_USER="${SUDO_USER:-$USER}"
BOOKSTACK_DIR="/var/www/bookstack"
DB_NAME="bookstack"
DB_USER="bookstack"
DB_PASS="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)"

CURRENT_IP="$(ip -4 addr show scope global | awk '/inet/{print $2}' | cut -d/ -f1 | head -n1)"
DOMAIN="$1"

############################################
# PRE-CHECKS
############################################
step_pre_checks() {
  [ "$EUID" -eq 0 ] || error_out "This role must be run as root"

  if [ -d /etc/nginx/conf.d ] && [ "$(ls -A /etc/nginx/conf.d)" ]; then
    error_out "Existing nginx configuration detected – fresh system required"
  fi

  if [ -d /var/lib/mysql ]; then
    error_out "Existing MariaDB/MySQL data detected – aborting"
  fi
}

############################################
# DOMAIN PROMPT
############################################
step_domain_prompt() {
  if [ -z "$DOMAIN" ]; then
    info_msg ""
    info_msg "Enter domain or IP for BookStack (example: docs.example.com or $CURRENT_IP):"
    read -r DOMAIN
  fi

  [ -n "$DOMAIN" ] || error_out "Domain is required"
}

############################################
# PACKAGE INSTALLATION
############################################
step_install_packages() {
  dnf install -y \
    git nginx mariadb-server \
    php php-cli php-fpm php-bcmath php-mbstring php-ldap \
    php-xml php-gd php-mysqlnd php-pecl-zip
}

############################################
# DATABASE SETUP
############################################
step_database_setup() {
  systemctl enable --now mariadb
  sleep 3

  mysql -u root <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
}

############################################
# BOOKSTACK DOWNLOAD
############################################
step_download_bookstack() {
  cd /var/www
  git clone https://source.bookstackapp.com/bookstack.git \
    --branch release --single-branch bookstack
}

############################################
# DEPENDENCIES
############################################
step_install_dependencies() {
  cd "$BOOKSTACK_DIR"
  php bookstack-system-cli download-vendor
}

############################################
# ENV CONFIGURATION
############################################
step_configure_env() {
  cd "$BOOKSTACK_DIR"
  cp .env.example .env

  sed -i \
    -e "s|^APP_URL=.*|APP_URL=http://${DOMAIN}|" \
    -e "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" \
    -e "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" \
    -e "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" .env

  php artisan key:generate --force --no-interaction
}

############################################
# DATABASE MIGRATION
############################################
step_migrate_database() {
  cd "$BOOKSTACK_DIR"
  php artisan migrate --force --no-interaction
}

############################################
# PERMISSIONS
############################################
step_set_permissions() {
  cd "$BOOKSTACK_DIR"

  chown -R "$SCRIPT_USER":apache .
  chmod -R 755 .
  chmod -R 775 storage bootstrap/cache public/uploads
  chmod 740 .env

  git config core.fileMode false
}

############################################
# NGINX CONFIG
############################################
step_configure_nginx() {
  cat >/etc/nginx/conf.d/bookstack.conf <<EOF
server {
  listen 80;
  server_name ${DOMAIN};

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
}

############################################
# FIREWALL & SELINUX
############################################
step_security() {
  firewall-cmd --permanent --add-service=http
  firewall-cmd --reload

  semanage fcontext -a -t httpd_sys_content_t "${BOOKSTACK_DIR}(/.*)?"
  semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/storage(/.*)?"
  semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/bootstrap/cache(/.*)?"
  semanage fcontext -a -t httpd_sys_rw_content_t "${BOOKSTACK_DIR}/public/uploads(/.*)?"

  restorecon -R "$BOOKSTACK_DIR"
}

############################################
# EXECUTION FLOW
############################################
info_msg "ADR installing: ${SOLUTION}"
info_msg "Log file: ${LOGPATH}"
sleep 1

info_msg "[1/10] Pre-installation checks"
step_pre_checks >>"$LOGPATH" 2>&1

info_msg "[2/10] Domain configuration"
step_domain_prompt >>"$LOGPATH" 2>&1

info_msg "[3/10] Installing packages"
step_install_packages >>"$LOGPATH" 2>&1

info_msg "[4/10] Database setup"
step_database_setup >>"$LOGPATH" 2>&1

info_msg "[5/10] Downloading BookStack"
step_download_bookstack >>"$LOGPATH" 2>&1

info_msg "[6/10] Installing PHP dependencies"
step_install_dependencies >>"$LOGPATH" 2>&1

info_msg "[7/10] Configuring environment"
step_configure_env >>"$LOGPATH" 2>&1

info_msg "[8/10] Database migration"
step_migrate_database >>"$LOGPATH" 2>&1

info_msg "[9/10] Permissions & ownership"
step_set_permissions >>"$LOGPATH" 2>&1

info_msg "[10/10] Nginx, firewall & SELinux"
step_configure_nginx >>"$LOGPATH" 2>&1
step_security >>"$LOGPATH" 2>&1

############################################
# SAVE THIS INFO
############################################
info_msg ""
info_msg "================= SAVE THIS INFO ================="
info_msg "Application : BookStack"
info_msg "URL         : http://${DOMAIN}/"
info_msg "Install dir : ${BOOKSTACK_DIR}"
info_msg "DB name     : ${DB_NAME}"
info_msg "DB user     : ${DB_USER}"
info_msg "DB password : ${DB_PASS}"
info_msg "Log file    : ${LOGPATH}"
info_msg ""
info_msg "Default login:"
info_msg "  Email     : admin@admin.com"
info_msg "  Password  : password"
info_msg "Based on Dan Brown - Bookstack for Almalinux 10 Script"
info_msg "=================================================="
