#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.2.4"

REPO_OWNER="skillmio"
REPO_NAME="adr"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_BASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents/roles"

CONFIG_DIR="$HOME/.config/adr"
CONFIG_FILE="$CONFIG_DIR/config
LOCALES_DIR="$CONFIG_DIR/locales"

DEFAULT_LANG="en"
LANG_CODE="$DEFAULT_LANG"

DISTRO_SUFFIX=""

# ==========================
# CONFIG & LOCALE
# ==========================

mkdir -p "$CONFIG_DIR" "$LOCALES_DIR"

[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"

ensure_locale() {
  local lang="$1"
  local target="$LOCALES_DIR/$lang/messages.sh"

  if [ ! -f "$target" ]; then
    mkdir -p "$LOCALES_DIR/$lang"
    curl -fsSL "$RAW_BASE_URL/locales/$lang/messages.sh" -o "$target" || return 1
  fi
}

# Load locale (fallback to EN)
ensure_locale "$LANG_CODE" || LANG_CODE="$DEFAULT_LANG"
ensure_locale "$LANG_CODE"
source "$LOCALES_DIR/$LANG_CODE/messages.sh"

msg() {
  "$1"
}

# ==========================
# SELF UPDATE
# ==========================

self_update() {
  msg UPDATE_CHECK
  remote=$(curl -fsSL "$RAW_BASE_URL/adr.sh" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  if [ -n "$remote" ] && [ "$remote" != "$CURRENT_VERSION" ]; then
    msg UPDATE_APPLY
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

detect_distro_suffix() {
  . /etc/os-release
  distro_id=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
  version_major=$(echo "$VERSION_ID" | cut -d '.' -f1)

  case "$distro_id" in
    almalinux|rhel|centos|centosstream|rocky|ol|oraclelinux)
      DISTRO_SUFFIX="almalinux_${version_major}"
      ;;
    *)
      DISTRO_SUFFIX=""
      ;;
  esac
}

# ==========================
# FUZZY MATCH
# ==========================

fuzzy_match() {
  local p="$1" s="$2"
  p=${p,,}; s=${s,,}
  local i=0 j=0
  while [[ $i -lt ${#p} && $j -lt ${#s} ]]; do
    [[ "${p:$i:1}" == "${s:$j:1}" ]] && ((i++))
    ((j++))
  done
  [[ $i -eq ${#p} ]]
}

# ==========================
# COMMANDS
# ==========================

# --- Show Help ---
show_help() {
  msg VERSION_HEADER
  msg USAGE
  msg OPTIONS
  msg EXAMPLES
}

# --- List Roles ---
list_roles() {
  local roles=()
  local cols=3
  local count=0

  while read -r r; do
    [[ "$r" == *_${DISTRO_SUFFIX}.sh ]] || continue
    roles+=( "${r%_${DISTRO_SUFFIX}.sh}" )
  done < <(
    curl -fsSL "$API_BASE_URL" \
      | grep '"name":' \
      | grep '.sh' \
      | cut -d '"' -f4
  )

  for role in "${roles[@]}"; do
    printf "%-20s" "$role"
    ((count++))
    (( count % cols == 0 )) && echo
  done

  (( count % cols != 0 )) && echo
}



# --- Find Roles ---
find_role() {
  query="$1"
  roles=$(curl -fsSL "$API_BASE_URL" | grep '"name":' | grep '.sh' | cut -d '"' -f4)
  for r in $roles; do
    [[ "$r" == *_${DISTRO_SUFFIX}.sh ]] || continue
    clean="${r%_${DISTRO_SUFFIX}.sh}"
    fuzzy_match "$query" "$clean" && echo " - $clean"
  done
}

run_role() {
  role="$1"

  # Always refresh locale before role execution
  rm -rf "$LOCALES_DIR/$LANG_CODE"
  ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"

  script="${role}_${DISTRO_SUFFIX}.sh"
  url="$RAW_BASE_URL/roles/$script"
  tmp=$(mktemp /tmp/adr-role.XXXXXX.sh)

  msg ROLE_DOWNLOAD
  if ! curl -fsSL "$url" -o "$tmp"; then
    msg ROLE_NOT_FOUND
    exit 1
  fi

  chmod +x "$tmp"
  sudo bash "$tmp"
  rm -f "$tmp"
}


set_lang() {
  LANG_CODE="$1"
  echo "LANG_CODE=$LANG_CODE" > "$CONFIG_FILE"
  rm -rf "$LOCALES_DIR/$LANG_CODE"
  ensure_locale "$LANG_CODE" || LANG_CODE="$DEFAULT_LANG"
  ensure_locale "$LANG_CODE"
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
  msg LANG_SET
}

diag() {
  msg DIAG_HEADER
  echo "ADR version:        $CURRENT_VERSION"
  echo "Binary path:        $(command -v adr)"
  echo "Config dir:         $CONFIG_DIR"
  echo "Language:           $LANG_CODE"
  echo "Locales dir:        $LOCALES_DIR"
  command -v curl >/dev/null && echo "Curl available:     yes" || echo "Curl available:     no"
  command -v sudo >/dev/null && echo "Sudo available:     yes" || echo "Sudo available:     no"
}

repair() {
  msg REPAIR_START
  rm -rf "$CONFIG_DIR"
  mkdir -p "$CONFIG_DIR" "$LOCALES_DIR"
  ensure_locale "$LANG_CODE" || ensure_locale "$DEFAULT_LANG"
  self_update "$@"
}

# ==========================
# MAIN
# ==========================

self_update "$@"
detect_distro_suffix

case "$1" in
  -h|--help) show_help ;;
  -l|--list) list_roles ;;
  -f|--find) find_role "$2" ;;
  -lg|--lang) set_lang "$2" ;;
  -d|--diag) diag ;;
  -r|--repair) repair ;;
  "") show_help ;;
  *) run_role "$1" ;;
esac
