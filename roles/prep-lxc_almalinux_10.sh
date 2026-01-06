#!/bin/bash

# ==========================================================================
# ADR's Proxmox LXC installation script - AL10
# ==========================================================================

# === PREPARATIONS ===

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
info_msg "${MSG_START_LXC}"
info_msg "${MSG_LOGPATH}"

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
  telnet \
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
  nc

# Update
sudo dnf update -y && sudo dnf upgrade -y

