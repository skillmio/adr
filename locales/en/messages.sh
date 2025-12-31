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
MSG_PROMPT_IP="Enter the IP address to use for accessing $SOLUTION"
MSG_PROMPT_URL="Enter the URL or hostname to use for accessing $SOLUTION"
MSG_USING_IP="IP has been set to"
MSG_USING_URL="URL has been set to"
MSG_INSTALL_MARIADB="Installing and Configure MariaDB"
MSG_INSTALL_APACHE="Installing and Configure Apache"
MSG_INSTALL_PHP="Installing and Configure PHP"
MSG_INSTALL_SOLUTION="Installing and Configure "
