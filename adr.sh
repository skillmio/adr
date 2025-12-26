#!/bin/bash

# ==========================
# ADR — Auto-Deploy Role
# ==========================

CURRENT_VERSION="0.1.0"

REPO_OWNER="skillmio"
REPO_NAME="adr"
BRANCH="main"

RAW_BASE_URL="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH"
API_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/contents"

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
        echo "ADR is designed for AlmaLinux and RHEL-compatible systems."
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
  echo
  echo "Examples:"
  echo "  adr wordpress"
  echo "  adr glpi"
  echo "  adr bookstack"
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

# === LIST AVAILABLE ROLES ===
list_available_roles() {
  echo "Fetching available ADR roles..."

  roles=$(curl -fsSL "$API_URL" | grep '"name":' | grep '.sh' | cut -d '"' -f 4 | grep -v '^adr.sh$')

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

# === RUN ROLE ===
run_role() {
  role="$1"

  if [[ -n "$DISTRO_SUFFIX" ]]; then
    role_script="${role}_${DISTRO_SUFFIX}.sh"
  else
    role_script="${role}.sh"
  fi

  script_url="$RAW_BASE_URL/$role_script"
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
  "")
    echo "Error: No role specified."
    echo "Run 'adr --help' for usage."
    exit 1
    ;;
  *)
    run_role "$1"
    ;;
esac
