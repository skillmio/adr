#!/bin/bash

set -u

# ===========================================
#   Beszel ADR Role – Easy Install
# ===========================================

clear

# === LOGGING ===
LOGPATH=$(realpath "beszel_install_$(date +%s).log")
touch "$LOGPATH"

function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# === LOAD ADR LOCALES ===
ADR_LANG="${ADR_LANG:-pt}"
ADR_LOCALES_BASE="${HOME}/.config/adr/locales"

if [[ -f "${ADR_LOCALES_BASE}/${ADR_LANG}/messages.sh" ]]; then
  source "${ADR_LOCALES_BASE}/${ADR_LANG}/messages.sh"
else
  source "${ADR_LOCALES_BASE}/en/messages.sh"
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

  # Prompting without redirection
  read -p "${MSG_PROMPT_IP} (${DEFAULT_IP}): " SERVER_IP
  SERVER_IP="${SERVER_IP:-$DEFAULT_IP}"

  read -p "${MSG_PROMPT_URL} (${DEFAULT_FQDN}): " ACCESS_URL
  ACCESS_URL="${ACCESS_URL:-$DEFAULT_FQDN}"

  info_msg "${MSG_USING_IP}: ${SERVER_IP}"
  info_msg "${MSG_USING_URL}: ${ACCESS_URL}"
}

function run_detect_version() {
  version=$(curl -fsSL https://api.github.com/repos/henrygd/beszel/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//')

  if [[ -z "$version" ]]; then
    info_msg "${MSG_ERR_VERSION}"
    exit 1
  fi

  info_msg "${MSG_VERSION_DETECTED}: v${version}"
}

function run_install_packages() {
  dnf install -y tar curl nginx
}

function run_create_user() {
  if ! id beszel &>/dev/null; then
    useradd -r -s /usr/sbin/nologin beszel
  fi
}

function run_detect_arch() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64) ARCH="arm64" ;;
    armv7l) ARCH="arm" ;;
    *) info_msg "${MSG_ERR_ARCH}: ${ARCH}"; exit 1 ;;
  esac

  OS=$(uname -s)
  TARBALL="beszel_${OS}_${ARCH}.tar.gz"
  TMP_PATH="/tmp/${TARBALL}"
}

function run_download_beszel() {
  DOWNLOAD_URL="https://github.com/henrygd/beszel/releases/download/v${version}/${TARBALL}"
  PROXY_URL="${GITHUB_PROXY_URL}${DOWNLOAD_URL}"

  curl -L --fail -o "$TMP_PATH" "$PROXY_URL" || {
    info_msg "${MSG_PROXY_FAIL}"
    curl -L --fail -o "$TMP_PATH" "$DOWNLOAD_URL"
  }

  file "$TMP_PATH" | grep -q gzip || exit 1
}

function run_install_beszel() {
  mkdir -p "${INSTALL_DIR}/beszel_data"
  tar -xzf "$TMP_PATH" -C "$INSTALL_DIR"
  chmod +x "${INSTALL_DIR}/beszel"
  chown -R beszel:beszel "$INSTALL_DIR"
}

function run_services() {
  cat <<EOF >/etc/systemd/system/beszel-hub.service
[Unit]
Description=Beszel Hub
After=network.target

[Service]
ExecStart=${INSTALL_DIR}/beszel serve --http 0.0.0.0:${PORT}
WorkingDirectory=${INSTALL_DIR}
User=beszel
Group=beszel
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now beszel-hub.service

  cat <<EOF >/etc/nginx/conf.d/beszel.conf
server {
  listen 80;
  server_name ${SERVER_IP} ${ACCESS_URL};

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

function run_firewall() {
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
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

# === SAVE THIS INFORMATION ===
info_msg "--------------------------------------------------"
info_msg "${MSG_SAVE_HEADER}"
info_msg "${MSG_SAVE_VERSION}: v${version}"
info_msg "${MSG_SAVE_PATH}: ${INSTALL_DIR}"
info_msg "${MSG_SAVE_SERVICE}: beszel-hub.service"
info_msg "${MSG_SAVE_URL}: http://${SERVER_IP} / http://${ACCESS_URL}"
info_msg "${MSG_SAVE_LOG}: ${LOGPATH}"
info_msg "--------------------------------------------------"
