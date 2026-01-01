#!/bin/bash

# ===========================================
# ADR's MySQL installation script - AL10
# ===========================================

# === PREPARATIONS ===

set -e
clear

# Define Solution early (needed for LOGPATH)
SOLUTION="MySQL"


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
TMP_DIR="/tmp"
MYSQL_ROOT_PASS="$(tr -dc 'A-Za-z0-9#.$' </dev/urandom | head -c 24)"


# === EXECUTION FLOW ===

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

# --- [1/2] INSTALLING PREREQUISITES ---
info_msg "[1/2] ${MSG_INSTALL_PREREQUISITES}"
{
sudo dnf install -y expect epel-release

} >>"$LOGPATH" 2>&1


# --- [2/2] INSTALLING MARIADB ---
info_msg "[2/2] ${MSG_INSTALL_MARIADB}"
{
  sudo dnf install -y mariadb-server
  sudo systemctl enable --now mariadb
  sleep 5

  sudo mysql <<SQL
-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';

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


# --- EXTRA GRAB INSTALLED VERSION ---
MARIADB_VERSION=$(rpm -q mariadb-server --qf '%{VERSION}-%{RELEASE}\n')



# === SAVE THIS INFO ===
info_msg "=================================================================="
info_msg " ${MSG_INSTALL_COMPLETE}"
info_msg "------------------------------------------------------------------"
info_msg " ${MSG_INSTALLED_VER}${SOLUTION}:${MARIADB_VERSION}"
info_msg " ${MSG_DB_ROOT}${MYSQL_ROOT_PASS}"
info_msg " ${MSG_LOGPATH}"
info_msg "=================================================================="
