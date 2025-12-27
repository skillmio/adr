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

#===BESZEL=====
MSG_STEP_COLLECT="Collecting required configuration"
MSG_STEP_VERSION="Detecting latest $SOLUTION version"
MSG_STEP_PACKAGES="Installing required system packages"
MSG_STEP_USER="Ensuring $SOLUTION system user exists"
MSG_STEP_ARCH="Detecting system architecture"
MSG_STEP_DOWNLOAD="Downloading $SOLUTION"
MSG_STEP_INSTALL="Installing $SOLUTION"
MSG_STEP_SERVICES="Configuring services"
MSG_STEP_FIREWALL="Configuring firewall"

MSG_PROMPT_IP="Enter the IP to access $SOLUTION"
MSG_PROMPT_URL="Enter the URL/hostname to access $SOLUTION"

MSG_USING_IP="Using IP"
MSG_USING_URL="Using URL"

MSG_TAIL_HINT="You can follow installation progress with:"
MSG_TAIL_CMD="tail -f"

MSG_VERSION_DETECTED="Latest version detected"
MSG_PROXY_FAIL="Proxy download failed, falling back to GitHub"
MSG_ERR_VERSION="Failed to determine latest version"
MSG_ERR_ARCH="Unsupported architecture"

MSG_SAVE_HEADER="Save this information"
MSG_SAVE_VERSION="Installed version"
MSG_SAVE_PATH="Install directory"
MSG_SAVE_SERVICE="Systemd service"
MSG_SAVE_URL="Access URL"
MSG_SAVE_LOG="Install log file"

