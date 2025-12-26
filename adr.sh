#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.3"

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
DEFAULT_LANG="en"
LANG_CODE="$DEFAULT_LANG"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCALES_DIR="$SCRIPT_DIR/locales"

# --------------------------
# Load config
# --------------------------
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
  fi
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

  printf "$(msg LANG_SET)\n" "$lang"
  msg LANG_PERSIST
}

# --------------------------
# Resolve language
# --------------------------
resolve_lang() {
  load_config

  if [ -n "$ADR_LANG" ]; then
    LANG_CODE="$ADR_LANG"
  else
    LANG_CODE="${LANG%%_*}"
  fi

  LANG_CODE="${LANG_CODE:-$DEFAULT_LANG}"
}

# --------------------------
# Load messages
# --------------------------
load_messages() {
  local lang="$1"
  local file="$LOCALES_DIR/$lang/messages.sh"

  if [ ! -f "$file" ]; then
    file="$LOCALES_DIR/$DEFAULT_LANG/messages.sh"
  fi

  # shellcheck source=/dev/null
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
# Detect distro
# --------------------------
DISTRO_SUFFIX=""

detect_distro_suffix() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release

    distro_id=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    version_major=$(echo "$VERSION_ID" | cut -d '.' -f1)

    case "$distro_id" in
      almalinux|rhel|centos|centosstream|rocky|ol|oraclelinux|eurolinux|clearos)
        DISTRO_SUFFIX="almalinux_${version_major}"
        ;;
      *)
        printf "$(msg UNSUPPORTED_DISTRO)\n" "$distro_id"
        msg SUPPORTED_DISTRO_HINT
        DISTRO_SUFFIX=""
        ;;
    esac

    [ -n "$DISTRO_SUFFIX" ] && \
      printf "$(msg DETECTED_SYSTEM)\n" "$distro_id" "$VERSION_ID" "$DISTRO_SUFFIX"
  fi
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

  if [ "$REMOTE_VERSION" != "$CURRENT_VERSION" ]; then
    printf "$(msg UPDATING)\n" "$REMOTE_VERSION"

    TMP_FILE=$(mktemp /tmp/adr.XXXXXX)
    curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$TMP_FILE" || exit 1
    chmod +x "$TMP_FILE"

    sudo mv "$TMP_FILE" /usr/local/bin/adr
    sudo chmod +x /usr/local/bin/adr

    msg UPDATED_SUCCESS
    exit 0
  fi
}

# --------------------------
# Fuzzy match (subsequence)
# --------------------------
fuzzy_match() {
  local pattern="$1"
  local string="$2"

  pattern=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
  string=$(echo "$string" | tr '[:upper:]' '[:lower:]')

  local i=0 j=0

  while [ $i -lt ${#pattern} ] && [ $j -lt ${#string} ]; do
    [ "${pattern:$i:1}" = "${string:$j:1}" ] && ((i++))
    ((j++))
  done

  [ $i -eq ${#pattern} ]
}

# --------------------------
# List roles
# --------------------------
list_roles() {
  msg AVAILABLE_ROLES
  echo

  roles=$(curl -fsSL "$API_URL" | grep '"name":' | cut -d '"' -f4)

  for role in $roles; do
    scripts=$(curl -fsSL "$API_URL/$role" | grep "$DISTRO_SUFFIX.sh" || true)
    [ -n "$scripts" ] && echo " - $role"
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
  local tmp

  printf "$(msg DEPLOYING_ROLE)\n" "$role"

  tmp=$(mktemp "/tmp/${role}.XXXXXX.sh")

  if ! curl -fsSL "$url" -o "$tmp"; then
    printf "$(msg ROLE_NOT_FOUND)\n" "$role"
    exit 1
  fi

  chmod +x "$tmp"
  sudo bash "$tmp"
  rm -f "$tmp"
}

# --------------------------
# Argument parsing
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
