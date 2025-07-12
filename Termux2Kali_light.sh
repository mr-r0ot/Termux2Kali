#!/data/data/com.termux/files/usr/bin/env bash
set -e

# 1) update Termux & install proot-distro
pkg update && pkg upgrade -y
pkg install -y proot proot-distro wget

# 2) install Debian if missing
echo "[*] Installing Debian..."
proot-distro install debian

# 3) bootstrap Kali CLI tools (once)
echo "[*] Adding Kali repo & installing all CLI tools..."
proot-distro login debian -- bash -lc "
    set -e
    apt update
    apt install -y gnupg2 curl
    # add Kali Rolling key & repo
    wget -q -O - https://archive.kali.org/archive-key.asc | apt-key add -
    echo 'deb http://http.kali.org/kali kali-rolling main contrib non-free' \
      >> /etc/apt/sources.list
    apt update
    # install every non‑GUI Kali package
    apt install -y kali-linux-headless
    # clean up
    apt clean
    rm -rf /var/lib/apt/lists/*
  "
  

echo "[+] Kali CLI tools installed."


# 4) launch Debian shell
exho "[INFO] You can always enter the penetration testing environment with this command. >>> proot-distro login debian"
echo "[*] Launching Debian..."

exec proot-distro login debian
