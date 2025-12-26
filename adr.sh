#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.6"

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
    UPDATE) echo "  --self-update         Update ADR to latest version" ;;
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
    UPDATE_AVAILABLE) echo "New ADR version available:" ;;
    UPDATE_DONE) echo "ADR updated successfully." ;;
    UNSUPPORTED_DISTRO) echo "Warning: unsupported distro." ;;
    DETECTED) echo "Detected system:" ;;
    *) echo "$1" ;;
  esac
}

# ==========================
# LANGUAGE HANDLING
# ==========================
resolve_lang() {
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
  LANG_CODE="${ADR_LANG:-$DEFAULT_LANG}"
}

ensure_locale() {
  local lang="$1"
  local local_file="$LOCALES_DIR/$lang/messages.sh"
  local remote_file="$RAW_BASE_URL/locales/$lang/messages.sh"

  mkdir -p "$LOCALES_DIR/$lang"

  if [ ! -f "$local_file" ]; then
    curl -fsSL "$remote_file" -o "$local_file" 2>/dev/null || return 1
  fi
}

load_messages() {
  if ! ensure_locale "$LANG_CODE"; then
    LANG_CODE="$DEFAULT_LANG"
    ensure_locale "$DEFAULT_LANG"
  fi

  local file="$LOCALES_DIR/$LANG_CODE/messages.sh"
  [ -f "$file" ] && source "$file"
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
# SYSTEM DETECTION
# ==========================
DISTRO_SUFFIX=""

detect_distro_suffix() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    version=$(echo "$VERSION_ID" | cut -d '.' -f1)

    case "$distro" in
      almalinux|rhel|centos|centosstream|rocky|ol|oraclelinux|eurolinux|clearos)
        DISTRO_SUFFIX="almalinux_${version}"
        msg DETECTED
        echo "  $distro $VERSION_ID → $DISTRO_SUFFIX"
        ;;
      *)
        msg UNSUPPORTED_DISTRO
        ;;
    esac
  fi
}

# ==========================
# UPDATE HANDLING (NO SILENT UPDATES)
# ==========================
check_update() {
  msg UPDATE_CHECK
  remote=$(curl -fsSL "$RAW_BASE_URL/adr.sh" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  if [ -n "$remote" ] && [ "$remote" != "$CURRENT_VERSION" ]; then
    echo
    msg UPDATE_AVAILABLE
    echo "  $remote"
    echo "Run: sudo adr --self-update"
    echo
  fi
}

perform_update() {
  tmp=$(mktemp /tmp/adr.XXXXXX)
  curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$tmp" || exit 1
  chmod +x "$tmp"
  sudo mv "$tmp" /usr/local/bin/adr
  sudo chmod +x /usr/local/bin/adr
  msg UPDATE_DONE
  exit 0
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
  query="$1"
  msg SEARCHING
  echo "  $query"

  roles=$(curl -fsSL "$ROLES_API_URL" | grep '"name":' | cut -d '"' -f4)
  found=0

  for r in $roles; do
    base="${r%.sh}"
    [[ "$base" == *_${DISTRO_SUFFIX} ]] || continue
    clean="${base%_${DISTRO_SUFFIX}}"

    if fuzzy_match "$query" "$clean"; then
      echo " - $clean"
      found=1
    fi
  done

  [ $found -eq 0 ] && msg NO_MATCH
}

run_role() {
  role="$1"
  script="${role}_${DISTRO_SUFFIX}.sh"
  url="$RAW_BASE_URL/roles/$script"
  tmp=$(mktemp "/tmp/$role.XXXX.sh")

  msg DOWNLOAD_ROLE
  echo "  $role"

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
  msg UPDATE
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
check_update

# ==========================
# ARGUMENT PARSING
# ==========================
case "$1" in
  -h|--help)
    show_help
    ;;
  -l|--list)
    detect_distro_suffix
    list_roles
    ;;
  -f|--find)
    detect_distro_suffix
    find_role "$2"
    ;;
  --lang)
    save_lang "$2"
    ;;
  --self-update)
    perform_update
    ;;
  "")
    show_help
    ;;
  *)
    detect_distro_suffix
    run_role "$1"
    ;;
esac
