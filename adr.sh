#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.4"

REPO_OWNER="skillmio"
REPO_NAME="adr"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/roles"

# --------------------------
# Config & Language
# --------------------------

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/adr"
CONFIG_FILE="$CONFIG_DIR/config"
LOCALES_DIR="$CONFIG_DIR/locales"

DEFAULT_LANG="en"
LANG_CODE="$DEFAULT_LANG"

# --------------------------
# Load config
# --------------------------
load_config() {
  [ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"
}

# --------------------------
# Ensure locale exists (download if missing)
# --------------------------
ensure_locale() {
  local lang="$1"
  local local_file="$LOCALES_DIR/$lang/messages.sh"
  local remote_file="$RAW_BASE_URL/locales/$lang/messages.sh"

  mkdir -p "$LOCALES_DIR/$lang"

  if [ ! -f "$local_file" ]; then
    curl -fsSL "$remote_file" -o "$local_file" 2>/dev/null || return 1
  fi
}

# --------------------------
# Load messages
# --------------------------
load_messages() {
  local lang="$1"

  ensure_locale "$lang" || ensure_locale "$DEFAULT_LANG"

  local file="$LOCALES_DIR/$lang/messages.sh"
  [ ! -f "$file" ] && file="$LOCALES_DIR/$DEFAULT_LANG/messages.sh"

  if [ ! -f "$file" ]; then
    echo "Fatal: Unable to load language files."
    exit 1
  fi

  source "$file"
}

# --------------------------
# Message helpers
# --------------------------
msg() {
  echo "${MESSAGES[$1]}"
}

msgf() {
  printf "${MESSAGES[$1]}\n" "$2"
}

# --------------------------
# Save language (persistent)
# --------------------------
save_lang() {
  local lang="$1"

  mkdir -p "$CONFIG_DIR"
  {
    echo "# ADR configuration"
    echo "ADR_LANG=$lang"
  } > "$CONFIG_FILE"

  load_messages "$lang"

  msgf LANG_SET "$lang"
  msg LANG_PERSIST
}

# --------------------------
# Resolve language
# --------------------------
resolve_lang() {
  load_config
  LANG_CODE="${ADR_LANG:-${LANG%%_*}}"
  LANG_CODE="${LANG_CODE:-$DEFAULT_LANG}"
}

# --------------------------
# Detect distro
# --------------------------
DISTRO_SUFFIX=""

detect_distro_suffix() {
  [ -f /etc/os-release ] || return

  . /etc/os-release

  distro_id=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  version_major=$(echo "$VERSION_ID" | cut -d '.' -f1)

  case "$distro_id" in
    almalinux|rhel|centos|centosstream|rocky|ol|oraclelinux|eurolinux|clearos)
      DISTRO_SUFFIX="almalinux_${version_major}"
      ;;
    *)
      msgf UNSUPPORTED_DISTRO "$distro_id"
      msg SUPPORTED_DISTRO_HINT
      DISTRO_SUFFIX=""
      ;;
  esac

  [ -n "$DISTRO_SUFFIX" ] && \
    printf "$(msg DETECTED_SYSTEM)\n" "$distro_id" "$VERSION_ID" "$DISTRO_SUFFIX"
}

# --------------------------
# Help
# --------------------------
show_help() {
  msg USAGE
  echo
  msg HELP_HEADER
  echo "  -h, --help       $(msg HELP_HELP)"
  echo "  -l, --list       $(msg HELP_LIST)"
  echo "  -f, --find       $(msg HELP_FIND)"
  echo "  --lang <code>    $(msg HELP_LANG)"
  echo
  msg HELP_EXAMPLES
  echo "  $(msg HELP_EXAMPLE_DEPLOY)"
  echo "  $(msg HELP_EXAMPLE_FIND)"
  echo "  $(msg HELP_EXAMPLE_LANG)"
}

# --------------------------
# Self-update
# --------------------------
self_update() {
  msg CHECKING_UPDATES

  REMOTE_SCRIPT=$(curl -fsSL "$RAW_BASE_URL/adr.sh")
  REMOTE_VERSION=$(echo "$REMOTE_SCRIPT" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  [ "$REMOTE_VERSION" = "$CURRENT_VERSION" ] && return

  printf "$(msg UPDATING)\n" "$REMOTE_VERSION"

  TMP_FILE=$(mktemp /tmp/adr.XXXXXX)
  curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$TMP_FILE" || exit 1
  chmod +x "$TMP_FILE"

  sudo mv "$TMP_FILE" /usr/local/bin/adr
  sudo chmod +x /usr/local/bin/adr

  msg UPDATED_SUCCESS
  exit 0
}

# --------------------------
# Fuzzy match
# --------------------------
fuzzy_match() {
  local p="$1" s="$2"
  p=$(echo "$p" | tr '[:upper:]' '[:lower:]')
  s=$(echo "$s" | tr '[:upper:]' '[:lower:]')

  local i=0 j=0
  while [ $i -lt ${#p} ] && [ $j -lt ${#s} ]; do
    [ "${p:$i:1}" = "${s:$j:1}" ] && ((i++))
    ((j++))
  done
  [ $i -eq ${#p} ]
}

# --------------------------
# List roles
# --------------------------
list_roles() {
  msg AVAILABLE_ROLES
  echo

  roles=$(curl -fsSL "$API_URL" | grep '"name":' | cut -d '"' -f4)

  for role in $roles; do
    curl -fsSL "$API_URL/$role" | grep -q "$DISTRO_SUFFIX.sh" && echo " - $role"
  done
}

# --------------------------
# Find roles
# --------------------------
find_role() {
  local query="$1"
  [ -z "$query" ] && { msg NO_SEARCH_TERM; exit 1; }

  msg MATCHING_ROLES
  echo

  roles=$(curl -fsSL "$API_URL" | grep '"name":' | cut -d '"' -f4)
  found=false

  for role in $roles; do
    if fuzzy_match "$query" "$role"; then
      echo " - $role"
      found=true
    fi
  done

  [ "$found" = false ] && msg NO_MATCHING_ROLES
}

# --------------------------
# Run role
# --------------------------
run_role() {
  local role="$1"
  local script="${role}_${DISTRO_SUFFIX}.sh"
  local url="$RAW_BASE_URL/roles/$role/$script"

  msgf DEPLOYING_ROLE "$role"

  tmp=$(mktemp "/tmp/${role}.XXXXXX.sh")

  if ! curl -fsSL "$url" -o "$tmp"; then
    msgf ROLE_NOT_FOUND "$role"
    exit 1
  fi

  chmod +x "$tmp"
  sudo bash "$tmp"
  rm -f "$tmp"
}

# --------------------------
# Parse arguments
# --------------------------
POSITIONAL=()
ACTION=""
QUERY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --lang)
      [ -z "$2" ] && { msg LANG_REQUIRED; exit 1; }
      save_lang "$2"
      exit 0
      ;;
    -h|--help) ACTION="help" ;;
    -l|--list) ACTION="list" ;;
    -f|--find) ACTION="find"; QUERY="$2"; shift ;;
    *) POSITIONAL+=("$1") ;;
  esac
  shift
done

set -- "${POSITIONAL[@]}"

# --------------------------
# Main
# --------------------------
resolve_lang
load_messages "$LANG_CODE"
self_update
detect_distro_suffix

case "$ACTION" in
  help) show_help ;;
  list) list_roles ;;
  find) find_role "$QUERY" ;;
  *)
    [ -z "$1" ] && { msg NO_ROLE_SPECIFIED; exit 1; }
    run_role "$1"
    ;;
esac
