#!/bin/bash

# ==========================================================================
# ADR's Proxmox LXC installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

# Define Solution early (needed for LOGPATH)
SOLUTION="LXC"

# --- LOGGING ---
LOGPATH="/tmp/${SOLUTION}_install_$(date +%s).log"

function info_msg() {
  echo "$1" | tee -a "$LOGPATH"
}

# --- LANGUAGE ---
CONFIG_FILE="$HOME/.config/adr/config"
LOCALES_DIR="$HOME/.config/adr/locales"

if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
else
  LANG_CODE="en"
fi

if [[ -f "$LOCALES_DIR/$LANG_CODE/messages.sh" ]]; then
  source "$LOCALES_DIR/$LANG_CODE/messages.sh"
else
  info_msg "Locale $LANG_CODE not found, falling back to English."
  source "$LOCALES_DIR/en/messages.sh"
fi

# === EXECUTION FLOW ===

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

echo " --- "
# --- [1/4] INSTALLING PREREQUISITES ---
info_msg "[1/1] ${MSG_INSTALL_PREREQUISITES}"

# Repo
sudo /usr/bin/crb enable
sudo dnf install -y epel-release

# Packages
sudo dnf install -y \
  wget \
  tcpdump \
  bind-utils \
  ncurses-term \
  htop \
  net-tools \
  traceroute \
  iputils \
  curl \
  jq \
  vim \
  less \
  NetworkManager NetworkManager-tui \
  nano \
  man \
  strace \
  lsof \
  sysstat \
  iotop \
  atop \
  iproute \
  whois \
  ethtool \
  nmap \
  ncurses \
  mtr \
  firewalld \
  openssh-server \
  selinux-policy selinux-policy-targeted policycoreutils \
  nc

# Update
sudo dnf update -y && sudo dnf upgrade -y

# Firewall
sudo systemctl enable --now firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload

# SSH
echo "PermitRootLogin yes" | sudo tee /etc/ssh/sshd_config.d/permit_root.conf
systemctl enable --now sshd

# Reboot LXC
reboot now
