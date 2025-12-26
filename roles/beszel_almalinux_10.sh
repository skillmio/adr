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
ADR_LANG="${ADR_LANG:-en}"
ADR_LOCALE_DIR="${ADR_LOCALE_DIR:-$HOME/.config/adr/locales/$ADR_LANG}"

if [[ -f "$ADR_LOCALE_DIR/messages.sh" ]]; then
  source "$ADR_LOCALE_DIR/messages.sh"
else
  source "$HOME/.config/adr/locales/en/messages.sh"
fi

# === GLOBALS ===
PORT=8090
INSTALL_DIR="/opt/beszel"
GITHUB_PROXY_URL="https://ghfast.top/"

DEFAULT_IP=$(hostname -I | awk '{print $1}')
DEFAULT_FQDN=$(hostname -f)

# === FUNCTIONS ===

function run_collect_config() {
  info_msg "${MSG_FOLLOW_PROGRESS}"
  info_msg "  tail -f $LOGPATH"
  echo

  read -p "${MSG_ENTER_IP} (${DEFAULT_IP}): " SERVER_IP
  SERVER_IP="${SERVER_IP:-$DEFAULT_IP}"

  read -p "${MSG_ENTER_URL} (${DEFAULT_FQDN}): " ACCESS_URL
  ACCESS_URL="${ACCESS_URL:-$DEFAULT_FQDN}"
}

function run_detect_version() {
  version=$(curl -fsSL https://api.github.com/repos/henrygd/beszel/releases/latest \
    | grep '"tag_name"' | cut -d '"' -f4 | sed 's/^v//')

  if [[ -z "$version" ]]; then
    info_msg "${MSG_VERSION_FAIL}"
    exit 1
  fi

  info_msg "$(printf "$MSG_VERSION_OK" "$version")"
}

function run_install_deps() {
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
    *) info_msg "$(printf "$MSG_UNSUPPORTED_ARCH" "$ARCH")"; exit 1 ;;
  esac

  OS=$(uname -s)
  TARBALL="beszel_${OS}_${ARCH}.tar.gz"
  TMP_PATH="/tmp/${TARBALL}"
}

function run_download_beszel() {
  DOWNLOAD_URL="https://github.com/henrygd/beszel/releases/download/v${version}/${TARBALL}"
  PROXY_URL="${GITHUB_PROXY_URL}${DOWNLOAD_URL}"

  curl -L --fail -o "$TMP_PATH" "$PROXY_URL" || \
  curl -L --fail -o "$TMP_PATH" "$DOWNLOAD_URL"

  file "$TMP_PATH" | grep -q gzip || {
    info_msg "$MSG_DOWNLOAD_FAIL"
    exit 1
  }
}

function run_install_beszel() {
  mkdir -p "${INSTALL_DIR}/beszel_data"
  tar -xzf "$TMP_PATH" -C "$INSTALL_DIR"
  chmod +x "${INSTALL_DIR}/beszel"
  chown -R beszel:beszel "$INSTALL_DIR"
}

function run_systemd_setup() {
  cat <<EOF > /etc/systemd/system/beszel-hub.service
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
}

function run_nginx_setup() {
  cat <<EOF > /etc/nginx/conf.d/beszel.conf
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

info_msg "[1/9] ${MSG_STEP_COLLECT_CONFIG}"
run_collect_config >>"$LOGPATH" 2>&1

info_msg "[2/9] ${MSG_STEP_DETECT_VERSION}"
run_detect_version >>"$LOGPATH" 2>&1

info_msg "[3/9] ${MSG_STEP_INSTALL_DEPS}"
run_install_deps >>"$LOGPATH" 2>&1

info_msg "[4/9] ${MSG_STEP_CREATE_USER}"
run_create_user >>"$LOGPATH" 2>&1

info_msg "[5/9] ${MSG_STEP_DETECT_ARCH}"
run_detect_arch >>"$LOGPATH" 2>&1

info_msg "[6/9] ${MSG_STEP_DOWNLOAD}"
run_download_beszel >>"$LOGPATH" 2>&1

info_msg "[7/9] ${MSG_STEP_INSTALL}"
run_install_beszel >>"$LOGPATH" 2>&1

info_msg "[8/9] ${MSG_STEP_SYSTEMD}"
run_systemd_setup >>"$LOGPATH" 2>&1

info_msg "[9/9] ${MSG_STEP_NGINX}"
run_nginx_setup >>"$LOGPATH" 2>&1
run_firewall >>"$LOGPATH" 2>&1

# === SAVE THIS INFO ===
info_msg "--------------------------------------------------"
info_msg "$MSG_INSTALL_DONE"
info_msg "$(printf "$MSG_ACCESS_URL" "$SERVER_IP" "$ACCESS_URL")"
info_msg "$(printf "$MSG_INSTALL_PATH" "$INSTALL_DIR")"
info_msg "$(printf "$MSG_LOG_PATH" "$LOGPATH")"
info_msg "--------------------------------------------------"
