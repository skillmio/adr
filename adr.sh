#!/usr/bin/env bash

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
LANG_CODE="$DEFAULT_LANG"
DISTRO_SUFFIX=""

# ==========================
# CONFIG & LANGUAGE
# ==========================

mkdir -p "$CONFIG_DIR" "$LOCALES_DIR"

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

msg() {
  local key="$1"
  shift
  if declare -F "$key" >/dev/null; then
    "$key" "$@"
  else
    MSG_MISSING "$key"
  fi
}

ensure_locale() {
  local lang="$1"
  local target="$LOCALES_DIR/$lang/messages.sh"

  mkdir -p "$LOCALES_DIR/$lang"

  if ! curl -fsSL "$RAW_BASE_URL/locales/$lang/messages.sh" -o "$target"; then
    return 1
  fi

  chmod +x "$target"
  return 0
}

load_language() {
  if ! ensure_locale "$LANG_CODE"; then
    LANG_CODE="$DEFAULT_LANG"
    ensure_locale "$DEFAULT_LANG"
  fi
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
}

save_lang() {
  local new_lang="$1"
  [ -z "$new_lang" ] && msg LANG_MISSING && exit 1

  LANG_CODE="$new_lang"
  mkdir -p "$CONFIG_DIR"
  echo "LANG_CODE=\"$LANG_CODE\"" > "$CONFIG_FILE"

  ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"

  msg LANG_SET "$LANG_CODE"
  msg LANG_SAVED
  exit 0
}

# ==========================
# SELF UPDATE
# ==========================

self_update() {
  msg UPDATE_CHECK
  local remote
  remote=$(curl -fsSL "$RAW_BASE_URL/adr.sh" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  if [ -n "$remote" ] && [ "$remote" != "$CURRENT_VERSION" ]; then
    msg UPDATE_APPLY "$remote"

    tmp=$(mktemp /tmp/adr.XXXXXX)
    curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$tmp" || exit 1
    chmod +x "$tmp"
    sudo mv "$tmp" /usr/local/bin/adr
    sudo chmod +x /usr/local/bin/adr

    rm -rf "$LOCALES_DIR/$LANG_CODE"
    ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"

    exec /usr/local/bin/adr "$@"
  fi
}

# ==========================
# DISTRO DETECTION
# ==========================

detect_distro() {
  [ -f /etc/os-release ] || return
  . /etc/os-release
  major=$(echo "$VERSION_ID" | cut -d. -f1)

  case "$ID" in
    almalinux|rhel|rocky|centos|ol)
      DISTRO_SUFFIX="almalinux_$major"
      ;;
  esac
}

# ==========================
# HELP
# ==========================

show_help() {
  echo
  msg HEADER "$CURRENT_VERSION"
  echo
  msg USAGE
  echo
  msg OPTIONS
  msg OPT_HELP
  msg OPT_LIST
  msg OPT_FIND
  msg OPT_LANG
  msg OPT_DIAG
  msg OPT_DIAG_FIX
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
# ROLES
# ==========================

list_roles() {
  detect_distro
  roles=$(curl -fsSL "$ROLES_API_URL" | grep '"name"' | grep '.sh' | cut -d '"' -f4)

  msg ROLES_AVAILABLE
  for r in $roles; do
    base="${r%.sh}"
    [[ "$base" == *_$DISTRO_SUFFIX ]] && echo " - ${base%_$DISTRO_SUFFIX}"
  done
}

find_role() {
  detect_distro
  local q="$1"
  [ -z "$q" ] && msg FIND_MISSING && exit 1

  roles=$(curl -fsSL "$ROLES_API_URL" | grep '"name"' | grep '.sh' | cut -d '"' -f4)

  msg FIND_SEARCH "$q"
  for r in $roles; do
    base="${r%.sh}"
    [[ "$base" == *_$DISTRO_SUFFIX ]] || continue
    clean="${base%_$DISTRO_SUFFIX}"
    [[ "$clean" == *"$q"* ]] && echo " - $clean"
  done
}

run_role() {
  detect_distro
  local role="$1"
  local script="${role}_${DISTRO_SUFFIX}.sh"
  local url="$RAW_BASE_URL/roles/$script"

  msg ROLE_DOWNLOAD "$role"
  tmp=$(mktemp /tmp/adr-role.XXXXXX)

  if ! curl -fsSL "$url" -o "$tmp"; then
    msg ROLE_NOT_FOUND
    exit 1
  fi

  chmod +x "$tmp"
  sudo bash "$tmp"
  rm -f "$tmp"
}

# ==========================
# DIAG
# ==========================

diag() {
  detect_distro
  msg DIAG_HEADER
  echo "ADR version:        $CURRENT_VERSION"
  echo "Binary path:        $(command -v adr)"
  echo "Config dir:         $CONFIG_DIR"
  echo "Language:           $LANG_CODE"
  echo "Locales dir:        $LOCALES_DIR"
  echo "Curl available:     $(command -v curl >/dev/null && echo yes || echo no)"
  echo "Sudo available:     $(command -v sudo >/dev/null && echo yes || echo no)"
  echo "Detected distro:    $DISTRO_SUFFIX"
}

diag_fix() {
  msg DIAG_FIX_INFO
  rm -rf "$LOCALES_DIR/$LANG_CODE"
  ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"
  self_update "$@"
}

# ==========================
# MAIN
# ==========================

load_language
self_update "$@"

case "$1" in
  -h|--help) show_help ;;
  -l|--list) list_roles ;;
  -f|--find) find_role "$2" ;;
  -lg|--lang) save_lang "$2" ;;
  -d|--diag) diag ;;
  -df|--diag-fix) diag_fix ;;
  "") show_help ;;
  *) run_role "$1" ;;
esac
