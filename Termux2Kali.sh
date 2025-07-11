#!/usr/bin/env bash
#
# install-kali.sh
# Fully automated Kali install in Termux
# - Full Kali NetHunter ARM64 rootfs (2025.1 full)
# - Full pentest meta-packages + neofetch
# - One-time user/pass prompt
# - Auto-login & neofetch on each Termux launch
#
# Usage: bash install-kali.sh

set -euo pipefail
IFS=$'\n\t'

INSTALL_DIR="$HOME/kali"
BASHRC="$HOME/.bashrc"
ROOTFS_URL="https://image-nethunter.kali.org/nethunter-fs/kali-2025.1/kali-nethunter-2025.1-rootfs-full-arm64.tar.xz"

# 1) Verify Termux environment
if [[ -z "${PREFIX##*com.termux*}" ]]; then
  echo "[+] Running inside Termux"
else
  echo "[!] This must be run in Termux"
  exit 1
fi

# 2) Ask for user credentials
read -p "Enter new Kali username: " KALI_USER
read -s -p "Enter Kali password (leave empty => no pass): " KALI_PASS; echo

# 3) Install dependencies
echo "[*] Updating Termux & installing proot, tar, wget..."
pkg update -y && pkg upgrade -y
pkg install -y proot tar wget

# 4) Download & extract Kali rootfs if needed
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "[*] Downloading Kali rootfs (~2.1 GiB)..."
  wget --quiet --show-progress -O "$HOME/kali-rootfs.tar.xz" "$ROOTFS_URL"
  echo "[*] Extracting to $INSTALL_DIR..."
  mkdir -p "$INSTALL_DIR"
  proot --link2symlink tar -xJf "$HOME/kali-rootfs.tar.xz" -C "$INSTALL_DIR"
  rm "$HOME/kali-rootfs.tar.xz"
fi

# 5) Configure Kali inside chroot
echo "[*] Configuring Kali and installing full toolset..."
proot --kill-on-exit --root-id -0 -r "$INSTALL_DIR" \
  -b /dev -b /proc -b /sys -b "$HOME:/root" -w /root /bin/bash -lc "
set -e
# Setup official repo
cat > /etc/apt/sources.list <<EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
#deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF
apt update -y && apt upgrade -y
# Install meta-packages & neofetch
apt install -y kali-linux-default kali-linux-full kali-tools-top10 neofetch python3 python3-pip
# Create user
id -u $KALI_USER &>/dev/null || useradd -m -s /bin/bash $KALI_USER
if [[ -n \"$KALI_PASS\" ]]; then
  echo \"$KALI_USER:$KALI_PASS\" | chpasswd
else
  passwd -d $KALI_USER
fi
# Lock root
passwd -l root
"

# 6) Enable auto-login & neofetch on each Termux start
echo "[*] Writing auto-login to $BASHRC..."
grep -q "AUTO_KALI_LOGIN" "$BASHRC" || cat >> "$BASHRC" <<'EOF'

# --- AUTO_KALI_LOGIN START ---
if [[ -z "$IN_KALI" ]]; then
  export IN_KALI=1
  clear
  neofetch
  read -p "Kali username: " __KU
  read -s -p "Kali password (leave empty => no pass): " __KP; echo
  exec proot --kill-on-exit --root-id -0 -r "'$INSTALL_DIR'" \
       -b /dev -b /proc -b /sys -b "'$HOME':/root" -w /root \
       /bin/bash -lc "\
if [[ -n '\$__KP' ]]; then \
  echo \$__KP | su - \$__KU; \
else \
  su - \$__KU; \
fi"
fi
# --- AUTO_KALI_LOGIN END ---
EOF

# 7) Final message & drop into Kali
cat <<EOF

✅ Kali installation complete!
   - Next Termux sessions will auto-launch Kali,
     show neofetch and prompt for your credentials.

Launching Kali now…

EOF

exec proot --kill-on-exit --root-id -0 -r "$INSTALL_DIR" \
     -b /dev -b /proc -b /sys -b "$HOME:/root" -w /root \
     /bin/bash -lc "clear; neofetch; su - $KALI_USER"
