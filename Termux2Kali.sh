#!/usr/bin/env bash
#
# install-termux-kali
# Fully automated: turns Termux into persistent Kali Linux with full toolset
# Prompts you once for a user account (username & optional password),
# then every new Termux session asks for those credentials and drops you into your Kali user.
#
# Usage: bash install-termux-kali.sh

set -euo pipefail
IFS=$'\n\t'

DISTRO="kali-rolling"
MIRROR="http://http.kali.org/kali"

# 1) Check running in Termux
if [[ -z "${PREFIX##*com.termux*}" ]]; then
  echo "[+] Detected Termux"
else
  echo "[!] Please run this inside Termux"
  exit 1
fi

# 2) Prompt for desired Kali user
read -p "Enter new Kali username: " KALI_USER
read -s -p "Enter Kali password (leave empty => no password): " KALI_PASS; echo

# 3) Install Termux deps
echo "[*] Updating Termux & installing dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y proot-distro git wget

# 4) Install Kali rootfs
echo "[*] Installing Kali ($DISTRO) via proot-distro..."
proot-distro install "$DISTRO"

# 5) Inside Kali: configure APT & install full toolset + create user
echo "[*] Configuring Kali and installing all tools..."
proot-distro login "$DISTRO" -- bash -lc "
# set Kali repos
cat > /etc/apt/sources.list <<EOF
deb $MIRROR $DISTRO main contrib non-free
#deb-src $MIRROR $DISTRO main contrib non-free
EOF
apt update -y && apt upgrade -y

# install meta-packages (all Kali tools) + Python
apt install -y kali-linux-default kali-linux-full kali-tools-top10 python3 python3-pip

# create user & set password
useradd -m -s /bin/bash $KALI_USER
if [[ -n \"$KALI_PASS\" ]]; then
  echo \"$KALI_USER:$KALI_PASS\" | chpasswd
else
  passwd -d $KALI_USER
fi

# disable root login via password (optional)
passwd -l root
"

# 6) Configure Termux to auto-prompt & launch Kali on each session
echo "[*] Setting up auto-login in ~/.bashrc..."
cat >> ~/.bashrc <<'EOF'
# --- AUTO-KALI LOGIN ---
if [[ -z "$IN_KALI" ]]; then
  export IN_KALI=1
  # prompt each session
  read -p "Kali username: " __KU
  read -s -p "Kali password (leave empty => no pass): " __KP; echo
  # launch Kali as root, then switch to user
  exec proot-distro login kali-rolling -- bash -lc "\
if [[ -n '$__KP' ]]; then \
  echo $__KP | su - \$__KU; \
else \
  su - \$__KU; \
fi"
fi
# --- END AUTO-KALI LOGIN ---
EOF

# 7) Final message & immediate entry
cat <<EOF

✅ Installation complete!
   From now on, every Termux session will:

   1) Ask for your Kali username & password  
   2) Enter Kali Linux and switch to that user  

Just open a new Termux tab/window and enjoy Kali 🎉

EOF

# drop into Kali right now
exec proot-distro login "$DISTRO" -- bash -lc "su - $KALI_USER"
