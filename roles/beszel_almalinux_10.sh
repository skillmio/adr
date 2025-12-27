#!/bin/bash

# ===========================================
#   Beszel easy-install installation script
# ===========================================

clear

SOLUTION="beszel"

# === LOGGING ===
LOGPATH=$(realpath "beszel_install_$(date +%s).log")

function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# === GLOBAL VARIABLES ===
PORT=8090
INSTALL_DIR="/opt/beszel"
GITHUB_PROXY_URL="https://ghfast.top/"
TMP_DIR="/tmp"
CONFIG_FILE="$HOME/.config/adr/config"
LOCALES_DIR="$HOME/.config/adr/locales"

# Load language setting from ADR config
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  LANG_CODE="en"  # Default to 'en' if config file doesn't exist
fi

# Ensure the correct locale is sourced
if [[ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ]]; then
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
else
  info_msg "Locale $LANG_CODE not found, falling back to English."
  source "$LOCALES_DIR/en/messages.sh"
fi

# === FUNCTIONS ===

function prompt_user_inputs() {
  # Here we keep the prompts intact as requested
  read -p "${MSG_PROMPT_IP} ($(hostname -I | awk '{print $1}')): " SERVER_IP
  [ -z "$SERVER_IP" ] && SERVER_IP=$(hostname -I | awk '{print $1}')

  read -p "${MSG_PROMPT_URL} ($(hostname -f)): " ACCESS_URL
  [ -z "$ACCESS_URL" ] && ACCESS_URL=$(hostname -f)

  info_msg "${MSG_USING_IP}: ${SERVER_IP}"
  info_msg "${MSG_USING_URL}: ${ACCESS_URL}"
}

function get_latest_version() {
  version=$(curl -fsSL https://api.github.com/repos/henrygd/beszel/releases/latest \
    | grep '"tag_name"' \
    | cut -d '"' -f4 \
    | sed 's/^v//')

  if [ -z "$version" ]; then
    info_msg "${MSG_ERR_VERSION}"
    exit 1
  fi

  info_msg "${MSG_VERSION_DETECTED}: v${version}"
}

function install_required_packages() {
  dnf install -y tar curl nginx
}

function ensure_beszel_user() {
  id beszel &>/dev/null || useradd -r -s /usr/sbin/nologin beszel
}

function detect_architecture() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
    *) info_msg "Unsupported architecture: $ARCH"; exit 1 ;;
  esac

  OS=$(uname -s)
  TARBALL="beszel_${OS}_${ARCH}.tar.gz"
  TMP_PATH="${TMP_DIR}/${TARBALL}"
}

function download_beszel() {
  DOWNLOAD_URL="https://github.com/henrygd/beszel/releases/download/v${version}/${TARBALL}"
  PROXY_URL="${GITHUB_PROXY_URL}${DOWNLOAD_URL}"

  curl -L --fail -o "$TMP_PATH" "$PROXY_URL" || true

  if ! file "$TMP_PATH" | grep -q 'gzip compressed data'; then
    info_msg "${MSG_PROXY_FAIL}"
    curl -L --fail -o "$TMP_PATH" "$DOWNLOAD_URL"
  fi
}

function install_beszel() {
  mkdir -p "${INSTALL_DIR}/beszel_data"
  tar -xzf "$TMP_PATH" -C "$INSTALL_DIR"
  chmod +x "${INSTALL_DIR}/beszel"
  chown -R beszel:beszel "$INSTALL_DIR"
}

function configure_systemd() {
  tee /etc/systemd/system/beszel-hub.service > /dev/null <<EOF
[Unit]
Description=Beszel Hub Service
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/beszel serve --http 0.0.0.0:${PORT}
WorkingDirectory=${INSTALL_DIR}
User=beszel
Group=beszel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now beszel-hub.service
}

function configure_nginx() {
  tee /etc/nginx/conf.d/beszel.conf > /dev/null <<EOF
server {
    listen 80;
    server_name ${SERVER_IP} ${ACCESS_URL};

    access_log /var/log/nginx/beszel_access.log;
    error_log /var/log/nginx/beszel_error.log;

    location / {
        proxy_pass http://localhost:${PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

  setsebool -P httpd_can_network_connect 1
  nginx -t
  systemctl enable --now nginx
}

function configure_firewall() {
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
}

# === EXECUTION FLOW ===

info_msg "[1/9] ${MSG_STEP_COLLECT}"
info_msg "${MSG_TAIL_HINT}"
info_msg "  ${MSG_TAIL_CMD} ${LOGPATH}"
prompt_user_inputs

info_msg "[2/9] ${MSG_STEP_VERSION}"
get_latest_version >> "$LOGPATH" 2>&1

info_msg "[3/9] ${MSG_STEP_PACKAGES}"
install_required_packages >> "$LOGPATH" 2>&1

info_msg "[4/9] ${MSG_STEP_USER}"
ensure_beszel_user >> "$LOGPATH" 2>&1

info_msg "[5/9] ${MSG_STEP_ARCH}"
detect_architecture >> "$LOGPATH" 2>&1

info_msg "[6/9] ${MSG_STEP_DOWNLOAD}"
download_beszel >> "$LOGPATH" 2>&1

info_msg "[7/9] ${MSG_STEP_INSTALL}"
install_beszel >> "$LOGPATH" 2>&1

info_msg "[8/9] ${MSG_STEP_SERVICES}"
configure_systemd >> "$LOGPATH" 2>&1
configure_nginx >> "$LOGPATH" 2>&1

info_msg "[9/9] ${MSG_STEP_FIREWALL}"
configure_firewall >> "$LOGPATH" 2>&1

# === SAVE THIS INFORMATION ===
info_msg "------------------------------------------------------------"
info_msg "${MSG_SAVE_HEADER}"
info_msg "${MSG_SAVE_VERSION}: v${version}"
info_msg "${MSG_SAVE_PATH}: ${INSTALL_DIR}"
info_msg "${MSG_SAVE_SERVICE}: beszel-hub.service"
info_msg "${MSG_SAVE_URL}: http://${SERVER_IP} or http://${ACCESS_URL}"
info_msg "${MSG_SAVE_LOG}: ${LOGPATH}"
info_msg "------------------------------------------------------------"
