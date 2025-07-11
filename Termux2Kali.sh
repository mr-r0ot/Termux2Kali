#!/usr/bin/env bash
#
# install-termux-kali.sh
# Fully automated: turns Termux into persistent Kali Linux environment
# Detects the correct proot-distro name for Kali, installs full toolset,
# and prompts for a user account for every session.
#
# Usage: bash install-termux-kali.sh

set -euo pipefail
IFS=$'\n\t'

# 1) Ensure we're in Termux
if [[ -z "${PREFIX##*com.termux*}" ]]; then
  echo "[+] Detected Termux"
else
  echo "[!] Please run this inside Termux"
  exit 1
fi

# 2) Determine Kali distro alias in proot-distro
echo "[*] Detecting Kali alias in proot-distro..."
DISTRO_ALIAS=$(proot-distro list | awk '/[Kk]ali/ {print $1; exit}')
if [[ -z "$DISTRO_ALIAS" ]]; then
  echo "[!] Kali not found in proot-distro list. Available distros:"
  proot-distro list
  exit 1
fi
echo "[+] Found Kali distro as: $DISTRO_ALIAS"

# 3) Prompt user for credentials
read -p "Enter new Kali username: " KALI_USER
read -s -p "Enter Kali password (leave empty => no password): " KALI_PASS; echo

# 4) Install dependencies
echo "[*] Updating Termux & installing dependencies..."
pkg update -y && pkg upgrade -y
pkg install -y proot-distro git wget

# 5) Install Kali rootfs if not already
if ! proot-distro list | grep -q "^$DISTRO_ALIAS\s*installed"; then
  echo "[*] Installing Kali ($DISTRO_ALIAS)..."
  proot-distro install "$DISTRO_ALIAS"
else
  echo "[*] Kali ($DISTRO_ALIAS) already installed, skipping."
fi

# 6) Configure Kali: repos, full toolset, Python & create user
echo "[*] Configuring Kali and installing full toolset..."
proot-distro login "$DISTRO_ALIAS" -- bash -lc "
set -e
# set Kali repos
cat > /etc/apt/sources.list <<EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free
#deb-src http://http.kali.org/kali kali-rolling main contrib non-free
EOF
apt update -y && apt upgrade -y
# install meta-packages (all Kali tools) + Python
apt install -y kali-linux-default kali-linux-full kali-tools-top10 python3 python3-pip
# create user and set password (or no password)
id -u $KALI_USER &>/dev/null || useradd -m -s /bin/bash $KALI_USER
if [[ -n \"$KALI_PASS\" ]]; then
  echo \"$KALI_USER:$KALI_PASS\" | chpasswd
else
  passwd -d $KALI_USER
fi
# lock root password
passwd -l root
"

# 7) Auto-login on every new Termux session
echo "[*] Enabling auto-login in ~/.bashrc..."
grep -q "AUTO_KALI_LOGIN" ~/.bashrc || cat >> ~/.bashrc <<'EOF'

# --- AUTO_KALI_LOGIN ---
if [[ -z "\$IN_KALI" ]]; then
  export IN_KALI=1
  read -p "Kali username: " __KU
  read -s -p "Kali password (leave empty => no pass): " __KP; echo
  exec proot-distro login $DISTRO_ALIAS -- bash -lc "\
if [[ -n '\$__KP' ]]; then \
  echo \$__KP | su - \$__KU; \
else \
  su - \$__KU; \
fi"
fi
# --- END AUTO_KALI_LOGIN ---
EOF

# 8) Final message & immediate entry
cat <<EOF

✅ Installation complete!
   From now on, opening Termux will:

   1) Ask for your Kali username & password
   2) Enter Kali Linux and switch to that user

Just start a new Termux session to begin. Enjoy Kali! 🎉

EOF

# Enter Kali right now
exec proot-distro login "$DISTRO_ALIAS" -- bash -lc "su - $KALI_USER"
