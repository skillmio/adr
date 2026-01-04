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
TMP_DIR="/tmp"
INSTALL_DIR="/var/www/html"
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"
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
# --- [1/] INSTALLING PREREQUISITES ---
info_msg "[1/] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y epel-release
sudo dnf install -y wget curl tar 
#pgsql repo
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-10-x86_64/pgdg-redhat-repo-latest.noarch.rpm
} >>"$LOGPATH" 2>&1



# --- [2/] INSTALLING POSTGRESQL ---
info_msg "[2/] ${MSG_INSTALL_POSTGSQL}"
{
# Install PostgreSQL:
sudo dnf install -y postgresql18-server

# Optionally initialize the database and enable automatic start:
sudo /usr/pgsql-18/bin/postgresql-18-setup initdb
sudo systemctl enable postgresql-18
sudo systemctl start postgresql-18
  
} >>"$LOGPATH" 2>&1



# --- [3/] INSTALLING ZABBIX ---
info_msg "[3/] ${MSG_INSTALL_SOLUTION}"
{
  sudo dnf install -y httpd
  sudo systemctl enable --now httpd
} >>"$LOGPATH" 2>&1
