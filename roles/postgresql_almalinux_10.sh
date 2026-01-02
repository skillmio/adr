#!/bin/bash

# ==========================================================================
# ADR's PostgreSQL installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="PostgreSQL"


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
PORT=5432
TMP_DIR="/tmp"
PGADMIN_EMAIL="adr.$(tr -dc a-z0-9 </dev/urandom | head -c 8)@$(hostname -d)"
PGADMIN_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"


# === EXECUTION FLOW ===

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"


# --- USER PROMPTS ---
read -p "${MSG_PROMPT_IP} ($(hostname -I | awk '{print $1}')): " SERVER_IP
SERVER_IP=${SERVER_IP:-$(hostname -I | awk '{print $1}')}

info_msg "${MSG_USING_IP}: $SERVER_IP"

echo " --- "


# --- [1/5] INSTALLING PREREQUISITES ---
info_msg "[1/5] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release wget 

#pgsql repo
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-10-x86_64/pgdg-redhat-repo-latest.noarch.rpm

#pgadmin repo
sudo rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-redhat-repo-2-1.noarch.rpm

} >>"$LOGPATH" 2>&1


# --- [2/5] INSTALLING POSTGRESQL ---
info_msg "[2/5] ${MSG_INSTALL_POSTGSQL}"
{
# Install PostgreSQL:
sudo dnf install -y postgresql18-server

# Optionally initialize the database and enable automatic start:
sudo /usr/pgsql-18/bin/postgresql-18-setup initdb
sudo systemctl enable postgresql-18
sudo systemctl start postgresql-18
  
} >>"$LOGPATH" 2>&1


# --- [3/5] INSTALLING APACHE ---
info_msg "[3/5] ${MSG_INSTALL_APACHE}"
{
  sudo dnf install -y httpd
  sudo systemctl enable --now httpd
} >>"$LOGPATH" 2>&1



# --- [4/5] INSTALLING PGADMIN ---
info_msg "[4/5] ${MSG_INSTALL_PGADMIN}"
{
# Install for web mode only.
sudo dnf install -y pgadmin4-web

# prep 
sudo \
  PGADMIN_SETUP_EMAIL="$PGADMIN_EMAIL" \
  PGADMIN_SETUP_PASSWORD="$PGADMIN_PASS" \
  /usr/pgadmin4/bin/setup-web.sh --yes >>"$LOGPATH" 2>&1

} >>"$LOGPATH" 2>&1

# --- [5/5] ADJUSTING FIREWALL ---
info_msg "[5/5] ${MSG_FIREWALL}"
{
if systemctl is-active --quiet firewalld; then   # ← set -e safe
  sudo firewall-cmd --permanent --add-service=http
  sudo firewall-cmd --permanent --add-service=https
  sudo firewall-cmd --permanent --add-port=${PORT}/tcp
  sudo firewall-cmd --reload
fi
} >>"$LOGPATH" 2>&1

# --- EXTRA GRAB INSTALLED VERSION ---
POSTGRES_VERSION=$(rpm -q postgresql18-server --qf '%{VERSION}-%{RELEASE}\n')


# === SAVE THIS INFO ===
echo ""
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}-${POSTGRES_VERSION}"
info_msg " ${MSG_IP}${SERVER_IP}/pgadmin4"
info_msg " ${MSG_USER_LOGIN}${PGADMIN_EMAIL}"
info_msg " ${MSG_USER_PASS}${PGADMIN_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
