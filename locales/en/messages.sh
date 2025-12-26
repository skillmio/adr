HEADER() { echo "ADR — Auto-Deploy Role v$1"; }
USAGE() { echo "Usage: adr <role>"; }
OPTIONS() { echo "Options:"; }

OPT_HELP() { echo "  -h, --help          Show this help message"; }
OPT_LIST() { echo "  -l, --list          List available roles"; }
OPT_FIND() { echo "  -f, --find <name>   Find a role"; }
OPT_LANG() { echo "  -lg, --lang <code>  Set language (en, pt, fr)"; }
OPT_DIAG() { echo "  -d, --diag          Run diagnostics"; }
OPT_DIAG_FIX() { echo "  -df, --diag-fix     Repair ADR installation"; }

EXAMPLES() { echo "Examples:"; }
EX1() { echo "  adr wordpress        Install WordPress"; }
EX2() { echo "  adr --find stack     Find roles containing 'stack'"; }
EX3() { echo "  adr --lang pt        Set language to Portuguese"; }
EX4() { echo "  adr -d               Run diagnostics"; }
EX5() { echo "  adr -df              Repair ADR installation"; }

UPDATE_CHECK() { echo "Checking for ADR updates..."; }
UPDATE_APPLY() { echo "Updating ADR to version $1"; }

LANG_SET() { echo "Language set to $1"; }
LANG_SAVED() { echo "Language saved for future runs."; }
LANG_MISSING() { echo "Error: language code missing."; }

ROLES_AVAILABLE() { echo "Available roles:"; }
FIND_MISSING() { echo "Error: search term missing."; }
FIND_SEARCH() { echo "Searching roles for: $1"; }

ROLE_DOWNLOAD() { echo "Downloading role: $1"; }
ROLE_NOT_FOUND() { echo "Error: role not found."; }

DIAG_HEADER() { echo "ADR Diagnostic"; }
DIAG_FIX_INFO() { echo "Repairing ADR installation (internet required)..."; }

MSG_MISSING() { echo "Missing message key: $1"; }
