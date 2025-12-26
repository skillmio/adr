#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.8"

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

# ==========================
# ENGLISH FAILSAFE (ALWAYS AVAILABLE)
# ==========================
msg() {
  case "$1" in
    VERSION) echo "Version:" ;;
    USAGE) echo "Usage: adr <role>" ;;
    OPTIONS) echo "Options:" ;;
    HELP) echo "  -h, --help            Show this help message" ;;
    LIST) echo "  -l, --list            List available roles" ;;
    FIND) echo "  -f, --find <keyword>  Find a role (fuzzy search)" ;;
    LANG) echo "  --lang <code>         Set language permanently" ;;
    DOCTOR) echo "  doctor                Run ADR diagnostics" ;;
    EXAMPLES) echo "Examples:" ;;
    EX1) echo "  adr wordpress" ;;
    EX2) echo "  adr --find stack" ;;
    EX3) echo "  adr --lang pt" ;;
    LANG_SET) echo "Language set to %s" ;;
    LANG_PERSIST) echo "Language saved for future runs." ;;
    FETCH_ROLES) echo "Fetching available ADR roles..." ;;
    AVAILABLE_ROLES) echo "Available roles:" ;;
    SEARCHING) echo "Searching roles for:" ;;
    NO_MATCH) echo "No matching roles found." ;;
    DOWNLOAD_ROLE) echo "Downloading role:" ;;
    EXEC_ROLE) echo "Executing role:" ;;
    ROLE_NOT_FOUND) echo "Error: role not found." ;;
    UPDATE_CHECK) echo "Checking for ADR updates..." ;;
    UPDATE_APPLY) echo "Updating ADR to version" ;;
    UNSUPPORTED_DISTRO) echo "Warning: unsupported distro." ;;
    DETECTED) echo "Detected system:" ;;
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
  [ -f "$local_file" ] || curl -fsSL "$remote_file" -o "$local_file" 2>/dev/null
}

load_messages() {
  ensure_locale "$LANG_CODE" || LANG_CODE="$DEFAULT_LANG"
  ensure_locale "$LANG_CODE"
  [ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ] && source "$LOCALES_DIR/$LANG_CODE/messages.sh"
}

save_lang() {
  local lang="$1"

  mkdir -p "$CONFIG_DIR"
  echo "ADR_LANG=$lang" > "$CONFIG_FILE"

  LANG_CODE="$lang"
  load_messages

  printf "$(msg LANG_SET)\n" "$lang"
  msg LANG_PERSIST
}

# ==========================
# SELF UPDATE (AUTO)
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
    echo "Restarting ADR..."
    exec /usr/local/bin/adr "$@"
  fi
}

# ==========================
# SYSTEM DETECTION
# ==========================
DISTRO_SUFFIX=""

detect_distro_suffix() {
  [ -f /etc/os-release ] || return
  . /etc/os-release

  distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  version=$(echo "$VERSION_ID" | cut -d '.' -f1)

  case "$distro" in
    almalinux|rhel|centos|centosstream|rocky|ol|oraclelinux|eurolinux|clearos)
      DISTRO_SUFFIX="almalinux_${version}"
      ;;
    *)
      msg UNSUPPORTED_DISTRO
      ;;
  esac
}

# ==========================
# FUZZY MATCH
# ==========================
fuzzy_match() {
  local p=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  local s=$(echo "$2" | tr '[:upper:]' '[:lower:]')
  local i=0 j=0
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
  roles=$(curl -fsSL "$ROLES_API_URL" | grep '"name":' | cut -d '"' -f4)
  msg AVAILABLE_ROLES
  for r in $roles; do
    base="${r%.sh}"
    [[ "$base" == *_${DISTRO_SUFFIX} ]] && echo " - ${base%_${DISTRO_SUFFIX}}"
  done
}

find_role() {
  msg SEARCHING
  echo "  $1"
  roles=$(curl -fsSL "$ROLES_API_URL" | grep '"name":' | cut -d '"' -f4)
  for r in $roles; do
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
  if ! curl -fsSL "$url" -o "$tmp"; then
    msg ROLE_NOT_FOUND
    exit 1
  fi

  chmod +x "$tmp"
  msg EXEC_ROLE
  sudo bash "$tmp"
  rm -f "$tmp"
}

# ==========================
# DOCTOR
# ==========================
doctor() {
  echo "ADR Doctor"
  echo "=========="

  echo "ADR version:        $CURRENT_VERSION"
  echo "Binary path:        $(command -v adr)"
  echo "Config dir:         $CONFIG_DIR"
  echo "Config file:        $CONFIG_FILE"
  echo "Language:           $LANG_CODE"
  echo "Locales dir:        $LOCALES_DIR"

  locale_file="$LOCALES_DIR/$LANG_CODE/messages.sh"
  echo "Locale file:        $locale_file"
  [ -f "$locale_file" ] && echo "Locale status:      OK" || echo "Locale status:      MISSING"

  echo "Curl available:     $(command -v curl >/dev/null && echo yes || echo no)"
  echo "Sudo available:     $(command -v sudo >/dev/null && echo yes || echo no)"
  echo "GitHub reachable:   $(curl -fsSL https://github.com >/dev/null && echo yes || echo no)"
  echo "Detected distro:    ${DISTRO_SUFFIX:-unknown}"

  echo "Roles API reachable:"
  curl -fsSL "$ROLES_API_URL" >/dev/null && echo "  yes" || echo "  no"
}

doctor_fix() {
  echo "ADR Doctor — Fix mode"
  echo "====================="
  echo "This operation requires internet access."
  echo

  echo "Re-downloading locale for language: $LANG_CODE"
  rm -rf "$LOCALES_DIR/$LANG_CODE"

  if ensure_locale "$LANG_CODE"; then
    echo "Locale '$LANG_CODE' downloaded successfully."
  else
    echo "Failed to download locale '$LANG_CODE'. Falling back to English."
    ensure_locale "$DEFAULT_LANG"
  fi
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
  msg DOCTOR
  echo
  msg EXAMPLES
  msg EX1
  msg EX2
  msg EX3
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
# ARGUMENTS
# ==========================
case "$1" in
  -h|--help) show_help ;;
  -l|--list) list_roles ;;
  -f|--find) find_role "$2" ;;
  --lang) save_lang "$2" ;;
  doctor)
    [ "$2" = "--fix" ] && doctor_fix || doctor
    ;;
  "") show_help ;;
  *) run_role "$1" ;;
esac
