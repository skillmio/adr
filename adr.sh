#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.2.1"

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
    curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$tmp" || return
    chmod +x "$tmp"
    sudo mv "$tmp" /usr/local/bin/adr
    sudo chmod +x /usr/local/bin/adr
    exec /usr/local/bin/adr "$@"
  fi
}

# ==========================
# DISTRO DETECTION
# ==========================
detect_distro_suffix() {
  [ -f /etc/os-release ] || return
  . /etc/os-release
  case "$ID" in
    almalinux|rhel|centos|rocky|ol|oraclelinux)
      DISTRO_SUFFIX="almalinux_${VERSION_ID%%.*}"
      ;;
  esac
}

# ==========================
# FUZZY MATCH
# ==========================
fuzzy_match() {
  local p="${1,,}" s="${2,,}" i=0 j=0
  while [ $i -lt ${#p} ] && [ $j -lt ${#s} ]; do
    [ "${p:$i:1}" = "${s:$j:1}" ] && ((i++))
    ((j++))
  done
  [ $i -eq ${#p} ]
}

# ==========================
# ROLES
# ==========================
list_roles() {
  msg FETCH_ROLES
  curl -fsSL "$ROLES_API_URL" | grep '"name":' | cut -d '"' -f4 |
  while read -r r; do
    base="${r%.sh}"
    [[ "$base" == *_${DISTRO_SUFFIX} ]] && echo " - ${base%_${DISTRO_SUFFIX}}"
  done
}

find_role() {
  msg SEARCHING
  echo "  $1"
  curl -fsSL "$ROLES_API_URL" | grep '"name":' | cut -d '"' -f4 |
  while read -r r; do
    base="${r%.sh}"
    [[ "$base" == *_${DISTRO_SUFFIX} ]] || continue
    clean="${base%_${DISTRO_SUFFIX}}"
    fuzzy_match "$1" "$clean" && echo " - $clean"
  done
}

run_role() {
  script="${1}_${DISTRO_SUFFIX}.sh"
  url="$RAW_BASE_URL/roles/$script"
  tmp=$(mktemp "/tmp/$1.XXXX.sh")

  msg DOWNLOAD_ROLE
  curl -fsSL "$url" -o "$tmp" || { msg ROLE_NOT_FOUND; exit 1; }
  chmod +x "$tmp"
  msg EXEC_ROLE
  sudo bash "$tmp"
  rm -f "$tmp"
}

# ==========================
# DIAGNOSTICS
# ==========================
diag() {
  echo "$(msg DIAG_TITLE)"
  echo "==============="
  echo "ADR version:      $CURRENT_VERSION"
  echo "Binary path:      $(command -v adr)"
  echo "Language:         $LANG_CODE"
  echo "Locales dir:      $LOCALES_DIR"
  echo "Locale file:      $LOCALES_DIR/$LANG_CODE/messages.sh"
  echo "Curl available:   $(command -v curl >/dev/null && echo yes || echo no)"
  echo "GitHub reachable: $(curl -fsSL https://github.com >/dev/null && echo yes || echo no)"
  echo "Detected distro:  ${DISTRO_SUFFIX:-unknown}"
}

diag_fix() {
  echo "$(msg DIAG_FIX_TITLE)"
  echo "=========================="
  msg DIAG_INTERNET
  echo

  echo "Re-downloading ADR binary..."
  curl -fsSL "$RAW_BASE_URL/adr.sh" -o /tmp/adr && chmod +x /tmp/adr &&
    sudo mv /tmp/adr /usr/local/bin/adr

  echo "Re-downloading locale ($LANG_CODE)..."
  rm -rf "$LOCALES_DIR/$LANG_CODE"
  ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"

  msg DIAG_DONE
}

# ==========================
# HELP
# ==========================
show_help() {
  echo
  echo "ADR — Auto-Deploy Role"
  printf "%s %s\n" "$(msg VERSION)" "$CURRENT_VERSION"
  echo
  msg USAGE
  echo
  msg OPTIONS
  msg HELP
  msg LIST
  msg FIND
  msg LANG
  msg DIAG
  msg DIAG_FIX
  echo
  msg EXAMPLES
  msg EX1
  msg EX2
  msg EX3
  msg EX4
  msg EX5
  echo
}

# ==========================
# BOOTSTRAP
# ==========================
resolve_lang
load_messages
self_update "$@"
detect_distro_suffix

# ==========================
# ARGS
# ==========================
case "$1" in
  -h|--help) show_help ;;
  -l|--list) list_roles ;;
  -f|--find) find_role "$2" ;;
  -lg|--lang) save_lang "$2" ;;
  -d|--diag) diag ;;
  -d-f|--diag-fix) diag_fix ;;
  "") show_help ;;
  *) run_role "$1" ;;
esac
