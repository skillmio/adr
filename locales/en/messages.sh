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
