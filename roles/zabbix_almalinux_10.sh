#!/bin/bash

# ==========================================================================
# ADR's Zabbix installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="Zabbix"

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
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"



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
sudo dnf install -y wget curl tar policycoreutils-python-utils nginx
#pgsql repo
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-10-x86_64/pgdg-redhat-repo-latest.noarch.rpm

#locale 
sudo dnf install glibc-all-langpacks -y
sudo localectl set-locale LANG=en_US.UTF-8

} >>"$LOGPATH" 2>&1



# --- [2/4] INSTALLING POSTGRESQL ---
info_msg "[2/4] ${MSG_INSTALL_POSTGSQL}"
{
# Install PostgreSQL:
sudo dnf install -y postgresql18-server

# Optionally initialize the database and enable automatic start:
sudo /usr/pgsql-18/bin/postgresql-18-setup initdb
sudo systemctl enable postgresql-18
sudo systemctl start postgresql-18
  
} >>"$LOGPATH" 2>&1



# --- [3/4] INSTALLING ZABBIX ---
info_msg "[3/4] ${MSG_INSTALL_SOLUTION}"
{

 # Disable Zabbix packages provided by EPEL
 sudo sed -i '/^\[epel\]/,/^\[/ s/^excludepkgs=.*/excludepkgs=zabbix*/' /etc/yum.repos.d/epel.repo || \
  echo -e "\n[epel]\nexcludepkgs=zabbix*" | sudo tee -a /etc/yum.repos.d/epel.repo
  
 # Add repo
 rpm -Uvh https://repo.zabbix.com/zabbix/7.4/release/alma/10/noarch/zabbix-release-latest-7.4.el10.noarch.rpm
 dnf clean all 
 
 # Install Zabbix server, frontend, agent 
 dnf install -y zabbix-server-pgsql zabbix-web-pgsql zabbix-nginx-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent 
 
 # Create initial database
 sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD '${DB_PASS}';"
 sudo -u postgres createdb -O ${DB_USER} ${DB_NAME}
 zcat /usr/share/zabbix/sql-scripts/postgresql/server.sql.gz | sudo -u ${DB_USER} psql ${DB_NAME}
 
 # Testing connectivity
 PGPASSWORD="${DB_PASS}" psql -U "${DB_USER}" -d "${DB_NAME}" -h localhost -c "\\conninfo"

 # Edit zabbix config file
 sudo sed -i "s|^# DBPassword=.*|DBPassword=${DB_PASS}|" /etc/zabbix/zabbix_server.conf
 
 # Permissions
 chown -R zabbix:zabbix /var/log/zabbix
 chown -R zabbix:zabbix /run/zabbix
 
 #Selinux
 semanage fcontext -a -t zabbix_log_t "/var/log/zabbix(/.*)?"
 restorecon -Rv /var/log/zabbix
 semanage fcontext -a -t zabbix_var_run_t "/run/zabbix(/.*)?"
 restorecon -Rv /run/zabbix

 #Nginx - change listen and server
 sed -i \
  -e 's|^[[:space:]]*listen[[:space:]]\+8080;|    listen 80;|' \
  -e 's|^[[:space:]]*server_name[[:space:]]\+[^;]\+;|    server_name ${SERVER_IP} ${ACCESS_URL};|' \
  /etc/nginx/conf.d/zabbix.conf
  setsebool -P httpd_can_network_connect 1
  nginx -t
   
 # Enable services
 sudo systemctl restart zabbix-server zabbix-agent nginx php-fpm
 sudo systemctl enable zabbix-server zabbix-agent nginx php-fpm 

} >>"$LOGPATH" 2>&1


# --- [4/4] ADJUSTING FIREWALL ---
info_msg "[4/4] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then 
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --permanent --add-port=${PORT}/tcp
  sudo firewall-cmd --reload
fi
} >>"$LOGPATH" 2>&1



# --- EXTRA GRAB INSTALLED VERSION ---
XVERSION=$(rpm -q zabbix-release --qf '%{VERSION}-%{RELEASE}\n')


# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}=${XVERSION}"
info_msg " ${MSG_URL}${ACCESS_URL}"
info_msg " ${MSG_IP}${SERVER_IP}"
info_msg " ${MSG_USER_LOGIN} Admin"
info_msg " ${MSG_USER_PASS} zabbix"
info_msg " ${MSG_DB_NAME}${DB_NAME}"
info_msg " ${MSG_DB_USER}${DB_USER}"
info_msg " ${MSG_DB_PASS}${DB_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
