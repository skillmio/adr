# === ADR MSGs === 
VERSION_HEADER() { echo "ADR v$CURRENT_VERSION"; }
UPDATE_CHECK() { echo "Checking for ADR updates..."; }
UPDATE_APPLY() { echo "Updating ADR..."; }

USAGE() { echo "Usage: adr <role>"; }

OPTIONS() {
  echo
  echo "Options:"
  echo "  -h, --help        Show help"
  echo "  -l, --list        List roles"
  echo "  -f, --find        Find role"
  echo "  -lg, --lang       Set language"
  echo "  -d, --diag        Diagnostics"
  echo "  -r, --repair     Repair ADR"
}

EXAMPLES() {
  echo
  echo "Examples:"
  echo "  adr wordpress     Install WordPress"
  echo "  adr -f stack      Find a role"
  echo "  adr -lg pt        Set language"
  echo "  adr -d            Diagnostics"
  echo "  adr -r            Repair ADR"
}

ROLE_DOWNLOAD() { echo "Downloading role..."; }
ROLE_NOT_FOUND() { echo "Error: role not found."; }
LANG_SET() { echo "Language saved."; }
DIAG_HEADER() { echo "ADR Diagnostics"; }
REPAIR_START() { echo "Repairing ADR (internet required)..."; }



# === ROLE MSGs === 
MSG_START="=== Starting $SOLUTION installation ==="
MSG_LOGPATH=" Log file: $LOGPATH"
MSG_PROMPT_IP="Enter the IP address that will be used to access $SOLUTION"
MSG_PROMPT_URL="Enter the URL or Hostname that will be used to access $SOLUTION"
MSG_USING_IP="IP has been set to"
MSG_USING_URL="URL has been set to"
MSG_INSTALL_PREREQUISITES="Installing Required Packages"
MSG_INSTALL_MARIADB="Installing and Configuring MariaDB"
MSG_INSTALL_POSTGSQL="Installing and Configuring PostgreSQL"
MSG_INSTALL_APACHE="Installing and Configuring Apache"
MSG_INSTALL_NGINX="Installing and Configuring Nginx"
MSG_INSTALL_PHP="Installing and Configuring PHP"
MSG_INSTALL_PHPMYADMIN="Installing and Configuring phpMyAdmin"
MSG_INSTALL_PGADMIN="Installing and Configuring pgAdmin"
MSG_INSTALL_SOLUTION="Installing and Configuring $SOLUTION"
MSG_FIREWALL="Creating allow rules on the firewall"
MSG_INSTALL_COMPLETE="$SOLUTION installation completed (SAVE THIS INFO)"
MSG_URL=" Access URL: http://"
MSG_IP=" Access IP: http://"
MSG_INSTALL_PATH=" Install path: "
MSG_INSTALLED_VER=" Installed version: "
MSG_DB_NAME=" Database name: "
MSG_DB_USER=" DB User: "
MSG_DB_PASS=" DB Pass: "
MSG_DB_ROOT=" MySQL root password: "
MSG_USER_LOGIN=" Access User: "
MSG_USER_PASS=" Access Pass: "

