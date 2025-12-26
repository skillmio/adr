msg() {
  case "$1" in
    VERSION) echo "Version:" ;;
    USAGE) echo "Usage: adr <role>" ;;
    OPTIONS) echo "Options:" ;;
    HELP) echo "  -h, --help            Show this help message" ;;
    LIST) echo "  -l, --list            List available roles" ;;
    FIND) echo "  -f, --find <keyword>  Find a role (fuzzy search)" ;;
    LANG) echo "  -lg, --lang <code>    Set language permanently" ;;
    DIAG) echo "  -d, --diag            Run ADR diagnostics" ;;
    DIAG_FIX) echo "  -d-f, --diag-fix      Repair ADR installation" ;;
    EXAMPLES) echo "Examples:" ;;
    EX1) echo "  adr wordpress        Install WordPress" ;;
    EX2) echo "  adr -f stack         Find roles containing 'stack'" ;;
    EX3) echo "  adr -lg pt           Set language to Portuguese (en, fr available)" ;;
    EX4) echo "  adr -d               Run ADR diagnostics" ;;
    EX5) echo "  adr -d-f             Repair ADR installation" ;;
    LANG_SET) echo "Language set to %s" ;;
    LANG_PERSIST) echo "Language saved for future runs." ;;
    FETCH_ROLES) echo "Fetching available ADR roles..." ;;
    SEARCHING) echo "Searching roles for:" ;;
    NO_MATCH) echo "No matching roles found." ;;
    DOWNLOAD_ROLE) echo "Downloading role:" ;;
    EXEC_ROLE) echo "Executing role:" ;;
    ROLE_NOT_FOUND) echo "Error: role not found." ;;
    UPDATE_CHECK) echo "Checking for ADR updates..." ;;
    UPDATE_APPLY) echo "Updating ADR to version" ;;
    DIAG_TITLE) echo "ADR Diagnostics" ;;
    DIAG_FIX_TITLE) echo "ADR Diagnostics — Fix mode" ;;
    DIAG_INTERNET) echo "Internet access is required." ;;
    DIAG_DONE) echo "Fix completed." ;;
    *) echo "$1" ;;
  esac
}
