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

# --- Check for root ---
if [[ "$EUID" -ne 0 ]]; then
  #echo "This script must be run as root"
  echo "${MSG_B_ROOT}"
  exit 1
fi

# --- Hello Msg ---
info_msg "${MSG_START}"
info_msg "${MSG_LOGPATH}"

# --- USER PROMPTS ---
info_msg "${MSG_SELECT_CONTAINER}"

read -p "Choice [1]: " CONTAINER_MODE
CONTAINER_MODE=${CONTAINER_MODE:-1}

case "$CONTAINER_MODE" in
  1)
    CONTAINER_TYPE="normal"
    ;;
  2)
    CONTAINER_TYPE="template"
    ;;
  *)
    echo "Invalid option. Exiting."
    exit 1
    ;;
esac

info_msg "${MSG_SELECTED_CONTAINER}${CONTAINER_TYPE}"


echo " --- "
# --- [1/4] INSTALLING PREREQUISITES ---
info_msg "[1/1] ${MSG_INSTALL_PREREQUISITES}"

# Repo
dnf install -y epel-release
/usr/bin/crb enable

# Packages
dnf install -y \
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

# SELinux 
#sed -i \
#  -e 's/^SELINUX=.*/SELINUX=enforcing/' \
#  -e 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' \
#  /etc/selinux/config
#touch /.autorelabel

# Update
dnf update -y && dnf upgrade -y

# Firewall
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# SSH
echo "PermitRootLogin yes" | tee /etc/ssh/sshd_config.d/permit_root.conf
systemctl enable --now sshd


if [[ "$CONTAINER_TYPE" == "template" ]]; then

  # Clear logs
  find /var/log -type f -exec truncate -s 0 {} \;

  # Remove bash history
  rm -f /root/.bash_history
  find /home -name ".bash_history" -exec rm -f {} \;

  # Clear shell history for current session
  history -c

  # Remove machine-id (will be regenerated)
  truncate -s 0 /etc/machine-id
  rm -f /var/lib/dbus/machine-id
  ln -sf /etc/machine-id /var/lib/dbus/machine-id

  # Clean package cache
  dnf clean all
  rm -rf /var/cache/dnf

  # Remove temporary files
  rm -rf /tmp/* /var/tmp/*

  # Shutdown LXC
  shutdown now

fi

# Reboot LXC
reboot now
