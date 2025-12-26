#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.2.0"

REPO_OWNER="skillmio"
REPO_NAME="adr"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
ROLES_API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/roles"

CONFIG_DIR="$HOME/.config/adr"
CONFIG_FILE="$CONFIG_DIR/config"
LOCALES_DIR="$CONFIG_DIR/locales"

DEFAULT_LANG="en"
LANG_CODE=""
DISTRO_SUFFIX=""

# ==========================
# ENGLISH FAILSAFE
# ==========================
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

# ==========================
# LANGUAGE HANDLING
# ==========================
resolve_lang() {
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
  LANG_CODE="${ADR_LANG:-$DEFAULT_LANG}"
}

ensure_locale() {
  local lang="$1"
  local local_file="$LOCALES_DIR/$lang/messages.sh"
  local remote_file="$RAW_BASE_URL/locales/$lang/messages.sh"

  mkdir -p "$LOCALES_DIR/$lang"
  [ -f "$local_file" ] || curl -fsSL "$remote_file" -o "$local_file"
}

load_messages() {
  ensure_locale "$LANG_CODE" || LANG_CODE="$DEFAULT_LANG"
  ensure_locale "$LANG_CODE"
  [ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ] && source "$LOCALES_DIR/$LANG_CODE/messages.sh"
}

save_lang() {
  mkdir -p "$CONFIG_DIR"
  echo "ADR_LANG=$1" > "$CONFIG_FILE"

  LANG_CODE="$1"
  load_messages

  printf "$(msg LANG_SET)\n" "$LANG_CODE"
  msg LANG_PERSIST
}

# ==========================
# SELF UPDATE (always runs)
# ==========================
self_update() {
  msg UPDATE_CHECK
  remote=$(curl -fsSL "$RAW_BASE_URL/adr.sh" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  if [ -n "$remote" ] && [ "$remote" != "$CURRENT_VERSION" ]; then
    echo
    msg UPDATE_APPLY
    echo "  $remote"
    tmp=$(mktemp /tmp/adr.XXXXXX)
