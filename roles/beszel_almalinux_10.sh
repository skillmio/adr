#!/bin/bash

set -e

# ===========================
# BESZEL INSTALLATION SCRIPT
# ===========================

LOGPATH=$(realpath "beszel_install_$(date +%s).log")
touch "$LOGPATH"

# Function to print info message and log it
function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# Ensure the LANG_CODE is set from the ADR environment
CONFIG_FILE="$HOME/.config/adr/config"
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  LANG_CODE="en"  # Default to 'en' if config file doesn't exist
fi

LOCALES_DIR="$HOME/.config/adr/locales"

# Ensure the correct locale is sourced
if [[ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ]]; then
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
else
  info_msg "Locale $LANG_CODE not found, falling back to English."
  source "$LOCALES_DIR/en/messages.sh"
fi

# === GLOBALS ===
PORT=8090
INSTALL_DIR="/opt/beszel"
GITHUB_PROXY_URL="https://ghfast.top/"

DEFAULT_IP=$(hostname -I | awk '{print $1}')
DEFAULT_FQDN=$(hostname -f)

# === FUNCTIONS ===
function run_collect_config() {
  info_msg "${MSG_TAIL_HINT}"
  info_msg "  ${MSG_TAIL_CMD} ${LOGPATH}"
  echo

  echo -n "${MSG_PROMPT_IP} (${DEFAULT_IP}): "
  read SERVER_IP
  SERVER_IP="${SERVER_IP:-$DEFAULT_IP}"

  echo -n "${MSG_PROMPT_URL} (${DEFAULT_FQDN}): "
  read ACCESS_URL
  ACCESS_URL="${ACCESS_URL:-$DEFAULT_FQDN}"

  info_msg "${MSG_USING_IP}: ${SERVER_IP}"
  info_msg "${MSG_USING_URL}: ${ACCESS_URL}"
}

# Example function for downloading Beszel (same idea for other functions)
function run_download_beszel() {
  DOWNLOAD_URL="https://github.com/henrygd/beszel/releases/download/v${version}/${TARBALL}"
  PROXY_URL="${GITHUB_PROXY_URL}${DOWNLOAD_URL}"

  curl -L --fail -o "$TMP_PATH" "$PROXY_URL" || {
    info_msg "${MSG_PROXY_FAIL}"
    curl -L --fail -o "$TMP_PATH" "$DOWNLOAD_URL"
  }

  file "$TMP_PATH" | grep -q gzip || exit 1
}

# === EXECUTION FLOW ===

info_msg "[1/9] ${MSG_STEP_COLLECT}"
run_collect_config >>"$LOGPATH" 2>&1

info_msg "[2/9] ${MSG_STEP_VERSION}"
run_detect_version >>"$LOGPATH" 2>&1

info_msg "[3/9] ${MSG_STEP_PACKAGES}"
run_install_packages >>"$LOGPATH" 2>&1

info_msg "[4/9] ${MSG_STEP_USER}"
run_create_user >>"$LOGPATH" 2>&1

info_msg "[5/9] ${MSG_STEP_ARCH}"
run_detect_arch >>"$LOGPATH" 2>&1

info_msg "[6/9] ${MSG_STEP_DOWNLOAD}"
run_download_beszel >>"$LOGPATH" 2>&1

info_msg "[7/9] ${MSG_STEP_INSTALL}"
run_install_beszel >>"$LOGPATH" 2>&1

info_msg "[8/9] ${MSG_STEP_SERVICES}"
run_services >>"$LOGPATH" 2>&1

info_msg "[9/9] ${MSG_STEP_FIREWALL}"
run_firewall >>"$LOGPATH" 2>&1

info_msg "Installation completed successfully!"
