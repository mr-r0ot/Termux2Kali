#!/usr/bin/env bash
#
# install-termux-kali.sh
# Turn Termux into a *persistent* Kali Linux (CLI) using NetHunter ARM64 rootfs + proot
# Prompts once for a user account, then every session asks for credentials.
#
# Usage: bash install-termux-kali.sh

set -euo pipefail
IFS=$'\n\t'

ROOTFS_URL="https://images.offensive-security.com/kalifs/kalifs-latest/kalifs-arm64-minimal.tar.xz"
INSTALL_DIR="$HOME/kali"
PROFILE="$HOME/.bashrc"

# 1) Check Termux
if [[ -z "${PREFIX##*com.termux*}" ]]; then
  echo "[+] Running in Termux"
else
  echo "[!] Please run this inside Termux"
  exit 1
fi

# 2) Prompt for Kali user
read -p "Enter new Kali username: " KALI_USER
read -s -p "Enter Kali password (leave empty → no password): " KALI_PASS; echo

# 3) Install dependencies
echo "[*] Updating Termux & installing dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y proot tar wget

# 4) Download & extract Kali rootfs if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "[*] Downloading Kali NetHunter rootfs (~200MB)..."
  wget --progress=dot:giga -O "$HOME/kali-rootfs.tar.xz" "$ROOTFS_URL"
  echo "[*] Extracting rootfs to $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
  proot --link2symlink tar -xJf "$HOME/kali-rootfs.tar.xz" -C "$INSTALL_DIR"
  rm "$HOME/kali-rootfs.tar.xz"
fi

# 5) Inside Kali: configure APT & install full toolset + create user
echo "[*] Configuring Kali and installing full toolset..."
proot --kill-on-exit \
  --root-id \
  -0 \
  -r "$INSTALL_DIR" \
  -b /dev \
  -b /proc \
  -b /sys \
  -b "$HOME:/root" \
  -w /root /bin/bash -lc "
set -e
# set up official Kali repo
cat > /etc/apt/sources.list <<EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
#deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF
apt update -y && apt upgrade -y
# install all Kali tools + Python
apt install -y kali-linux-default kali-linux-full kali-tools-top10 python3 python3-pip
# add user
id -u $KALI_USER &>/dev/null || useradd -m -s /bin/bash $KALI_USER
if [[ -n \"$KALI_PASS\" ]]; then
  echo \"$KALI_USER:$KALI_PASS\" | chpasswd
else
  passwd -d $KALI_USER
fi
# lock root password
passwd -l root
"

# 6) Auto-login into Kali on each new Termux session
echo "[*] Enabling auto-login in $PROFILE..."
grep -q "AUTO_KALI_LOGIN" "$PROFILE" || cat >> "$PROFILE" <<'EOF'

# --- AUTO_KALI_LOGIN ---
if [[ -z "$IN_KALI" ]]; then
  export IN_KALI=1
  read -p "Kali username: " __KU
  read -s -p "Kali password (leave empty → no password): " __KP; echo
  # enter Kali and switch to user
  exec proot --kill-on-exit --root-id -0 -r "$HOME/kali" -b /dev -b /proc -b /sys -b "$HOME:/root" -w /root /bin/bash -lc "\
if [[ -n '\$__KP' ]]; then \
  echo \$__KP | su - \$__KU; \
else \
  su - \$__KU; \
fi"
fi
# --- END AUTO_KALI_LOGIN ---
EOF

# 7) Final message & immediate entry
cat <<EOF

✅ Installation complete!
   Next time you open Termux it will:

   1) Ask for your Kali credentials  
   2) Drop you into your Kali user shell with all tools available

Running Kali now...

EOF

exec proot --kill-on-exit --root-id -0 -r "$INSTALL_DIR" -b /dev -b /proc -b /sys -b "$HOME:/root" -w /root /bin/bash -lc "su - $KALI_USER"
