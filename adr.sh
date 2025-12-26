#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.2"

REPO_OWNER="skillmio"
REPO_NAME="adr"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_BASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

ROLES_DIR="roles"

DISTRO_SUFFIX=""

# === DETECT DISTRO AND VERSION ===
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
        echo "Warning: Unsupported distro '$distro_id'."
        echo "ADR targets AlmaLinux and RHEL-compatible systems."
        DISTRO_SUFFIX=""
        ;;
    esac

    if [ -n "$DISTRO_SUFFIX" ]; then
      echo "Detected system: $distro_id $VERSION_ID → $DISTRO_SUFFIX"
    fi
  fi
}

# === DISPLAY HELP ===
show_help() {
  echo "Usage: adr <role>"
  echo
  echo "Options:"
  echo "  -h, --help       Show this help message"
  echo "  -l, --list       List available roles"
  echo "  -f, --find       Find a role by name (fuzzy search)"
  echo
  echo "Examples:"
  echo "  adr wordpress"
  echo "  adr --find stack"
  echo "  adr -f wp"
  echo
}

# === SELF UPDATE ===
self_update() {
  echo "Checking for ADR updates..."
  echo "Local version:  $CURRENT_VERSION"

  REMOTE_SCRIPT=$(curl -fsSL "$RAW_BASE_URL/adr.sh")
  REMOTE_VERSION=$(echo "$REMOTE_SCRIPT" | grep '^CURRENT_VERSION=' | cut -d '"' -f2)

  echo "Remote version: $REMOTE_VERSION"

  if [[ "$REMOTE_VERSION" != "$CURRENT_VERSION" ]]; then
    echo "Updating ADR to version $REMOTE_VERSION..."

    TMP_FILE=$(mktemp /tmp/adr.XXXXXX)
    curl -fsSL "$RAW_BASE_URL/adr.sh" -o "$TMP_FILE" || exit 1
    chmod +x "$TMP_FILE"

    sudo mv "$TMP_FILE" /usr/local/bin/adr
    sudo chmod +x /usr/local/bin/adr

    echo "ADR updated successfully."
    exit 0
  fi
}

# === FUZZY MATCH (subsequence) ===
fuzzy_match() {
  local pattern="$1"
  local string="$2"

  pattern=$(echo "$pattern" | tr '[:upper:]' '[:lower:]')
  string=$(echo "$string" | tr '[:upper:]' '[:lower:]')

  local i=0
  local j=0

  while [ $i -lt ${#pattern} ] && [ $j -lt ${#string} ]; do
    if [ "${pattern:$i:1}" = "${string:$j:1}" ]; then
      ((i++))
    fi
    ((j++))
  done

  [ $i -eq ${#pattern} ]
}

# === FETCH ROLES FROM GITHUB ===
fetch_roles() {
  curl -fsSL "$API_BASE_URL/$ROLES_DIR" | grep '"name":' | grep '.sh' | cut -d '"' -f 4
}

# === LIST AVAILABLE ROLES ===
list_available_roles() {
  echo "Fetching available ADR roles..."

  roles=$(fetch_roles)

  echo
  echo "==========================================================="
  echo "                        Available Roles"
  echo "==========================================================="

  filtered=()
  for role in $roles; do
    base=$(basename "$role" .sh)
    if [[ "$base" == *_${DISTRO_SUFFIX} ]]; then
      filtered+=("${base%_${DISTRO_SUFFIX}}")
    fi
  done

  for r in "${filtered[@]}"; do
    printf " - %s\n" "$r"
  done

  echo
}

# === FIND ROLE (FUZZY) ===
find_role() {
  query="$1"

  if [ -z "$query" ]; then
    echo "Error: No search term provided."
    echo "Usage: adr --find <keyword>"
    exit 1
  fi

  echo "Searching ADR roles for: '$query'"

  roles=$(fetch_roles)

  matches=()
  for role in $roles; do
    base=$(basename "$role" .sh)

    if [[ "$base" == *_${DISTRO_SUFFIX} ]]; then
      clean="${base%_${DISTRO_SUFFIX}}"

      if fuzzy_match "$query" "$clean"; then
        matches+=("$clean")
      fi
    fi
  done

  if [ ${#matches[@]} -eq 0 ]; then
    echo "No matching roles found."
    exit 0
  fi

  echo
  echo "Matching roles:"
  for m in "${matches[@]}"; do
    printf " - %s\n" "$m"
  done

  echo
}

# === RUN ROLE ===
run_role() {
  role="$1"

  if [[ -n "$DISTRO_SUFFIX" ]]; then
    role_script="${role}_${DISTRO_SUFFIX}.sh"
  else
    role_script="${role}.sh"
  fi

  script_url="$RAW_BASE_URL/$ROLES_DIR/$role_script"
  tmp_file=$(mktemp "/tmp/${role}.XXXXXX.sh")

  echo "Downloading role: $role"
  if ! curl -fsSL "$script_url" -o "$tmp_file"; then
    echo "Error: Role '$role' not found."
    exit 1
  fi

  chmod +x "$tmp_file"
  echo "Executing role: $role"
  sudo bash "$tmp_file"
  rm -f "$tmp_file"
}

# === MAIN ===
self_update
detect_distro_suffix

case "$1" in
  -h|--help)
    show_help
    ;;
  -l|--list)
    list_available_roles
    ;;
  -f|--find)
    find_role "$2"
    ;;
  "")
    echo "Error: No role specified."
    echo "Run 'adr --help' for usage."
    exit 1
    ;;
  *)
    run_role "$1"
    ;;
esac
