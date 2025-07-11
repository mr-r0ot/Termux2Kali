#!/usr/bin/env bash
#
# install-kali-termux.sh
# A fully automated script to transform Termux into a persistent Kali Linux environment
# Usage: bash install-kali-termux.sh (run once)
# After installation, every new Termux session will automatically enter Kali

set -euo pipefail
IFS=$'\n\t'

# Configuration
KALI_DISTRO="kali"
KALI_RELEASE="kali-rolling"
KALI_MIRROR="http://http.kali.org/kali"

# 1. Verify running inside Termux
if [[ -z "${PREFIX##*com.termux*}" ]]; then
  echo "[+] Detected Termux environment"
else
  echo "[!] This installer must be run inside Termux"
  exit 1
fi

# 2. Update Termux and install dependencies
echo "[*] Updating Termux packages..."
pkg update -y && pkg upgrade -y

echo "[*] Installing dependencies: proot-distro, wget, git..."
pkg install -y proot-distro wget git

# 3. Install Kali Linux via proot-distro
echo "[*] Installing Kali Linux ($KALI_RELEASE)..."
proot-distro install "$KALI_DISTRO"

# 4. Configure Kali apt sources and install full toolset
echo "[*] Configuring Kali APT sources and installing complete toolset..."
proot-distro login "$KALI_DISTRO" -- bash -lc "
cat > /etc/apt/sources.list <<EOF
\
deb $KALI_MIRROR $KALI_RELEASE main contrib non-free
\
#deb-src $KALI_MIRROR $KALI_RELEASE main contrib non-free
EOF
apt update -y && apt upgrade -y
# Install meta-packages for full Kali toolset
apt install -y kali-linux-default kali-linux-full kali-tools-top10 python3 python3-pip
"    

# 5. Set up automatic launch of Kali on new Termux sessions
echo "[*] Configuring Termux to enter Kali on startup..."
BASHRC="$HOME/.bashrc"
# Append auto-login block if not present
if ! grep -q "AUTO_KALI_LOGIN" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'
# --- AUTO_KALI_LOGIN START ---
if [[ -z "$IN_KALI" ]]; then
  export IN_KALI=1
  exec proot-distro login kali
fi
# --- AUTO_KALI_LOGIN END ---
EOF
fi

# 6. Customize Kali banner (motd)
echo "[*] Setting custom Kali banner..."
proot-distro login "$KALI_DISTRO" -- bash -lc "
cat > /etc/motd <<'EOF'

  _____      _    _ _ _        _   _      _      _
 |  __ \    | |  | | (_)      | | | |    | |    | |
 | |  | | __| |  | | |_ _ __  | | | | ___| | ___| |_ ___ _ __
 | |  | |/ _\` |  | | | | '__| | | | |/ _ \ |/ _ \ __/ _ \ '__|
 | |__| | (_| |  | | | | |    | |_| |  __/ |  __/ ||  __/ |
 |_____/ \__,_|  |_|_|_|_|     \___/ \___|_|\___|\__\___|_|

 Welcome to Kali Linux on Termux!
 EOF
"

# 7. Final message and immediate entry into Kali
cat << EOF

✅ Installation complete! You will now be dropped into Kali Linux.
   Every future Termux session will automatically enter Kali.

EOF
# Enter Kali immediately
exec proot-distro login "$KALI_DISTRO"
