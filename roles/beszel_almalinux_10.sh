#!/bin/bash

# ===========================================
#   Beszel easy-install installation script
# ===========================================

clear

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

# === FUNCTIONS ===

function get_latest_version() {
  info_msg "Fetching latest Beszel version from GitHub..."

  version=$(curl -fsSL https://api.github.com/repos/henrygd/beszel/releases/latest \
    | grep '"tag_name"' \
    | cut -d '"' -f4 \
    | sed 's/^v//')

  if [ -z "$version" ]; then
    info_msg "ERROR: Failed to determine latest Beszel version"
    exit 1
  fi

  info_msg "Latest version detected: v${version}"
}

function prompt_access_details() {
  read -p "Please enter the IP you will use to access Beszel (leave blank to use $(hostname -I | awk '{print $1}')): " SERVER_IP
  [ -z "$SERVER_IP" ] && SERVER_IP=$(hostname -I | awk '{print $1}')

  read -p "Please enter the URL you will use to access Beszel (leave blank to use $(hostname -f)): " ACCESS_URL
  [ -z "$ACCESS_URL" ] && ACCESS_URL=$(hostname -f)
}

function install_required_packages() {
  dnf install -y tar curl nginx
}

function ensure_beszel_user() {
  if ! id beszel &>/dev/null; then
    useradd -r -s /usr/sbin/nologin beszel
  fi
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
    info_msg "Proxy download failed, falling back to direct GitHub..."
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

info_msg "[1/9] Detecting latest Beszel version..."
get_latest_version >> "$LOGPATH" 2>&1

info_msg "[2/9] Collecting access information..."
prompt_access_details >> "$LOGPATH" 2>&1

info_msg "[3/9] Installing required system packages..."
install_required_packages >> "$LOGPATH" 2>&1

info_msg "[4/9] Ensuring system user 'beszel' exists..."
ensure_beszel_user >> "$LOGPATH" 2>&1

info_msg "[5/9] Detecting system architecture..."
detect_architecture >> "$LOGPATH" 2>&1

info_msg "[6/9] Downloading Beszel ${version}..."
download_beszel >> "$LOGPATH" 2>&1

info_msg "[7/9] Installing Beszel..."
install_beszel >> "$LOGPATH" 2>&1

info_msg "[8/9] Configuring systemd and nginx..."
configure_systemd >> "$LOGPATH" 2>&1
configure_nginx >> "$LOGPATH" 2>&1

info_msg "[9/9] Configuring firewall..."
configure_firewall >> "$LOGPATH" 2>&1

# === SAVE THIS INFORMATION ===
info_msg "------------------------------------------------------------"
info_msg "Beszel installation completed successfully"
info_msg "- Installed version:            v${version}"
info_msg "- Install directory:            ${INSTALL_DIR}"
info_msg "- Systemd service:              beszel-hub.service"
info_msg "- Runs as user:                 beszel"
info_msg "- Web UI access:                http://${SERVER_IP} or http://${ACCESS_URL}"
info_msg "- Listening port:               ${PORT}"
info_msg "- Install log file:             ${LOGPATH}"
info_msg "------------------------------------------------------------"
