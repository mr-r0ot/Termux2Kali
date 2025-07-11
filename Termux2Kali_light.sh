#!/usr/bin/env bash
#
# Termux2Kali_ultimate.sh
# The most comprehensive Kali‑style tool installer for Termux
# - Native pkg tools + Python/Ruby/NodeJS/Go/Rust/Cargo
# - Git‑based frameworks & scripts
# - Custom “Welcome to kali” banner on each launch
#
# Usage: bash Termux2Kali_ultimate.sh

set -euo pipefail
IFS=$'\n\t'

BASHRC="$HOME/.bashrc"

echo -e "\n[*] Updating Termux & enabling repos…"
pkg update -y && pkg upgrade -y
pkg install -y unstable-repo root-repo

echo -e "\n[*] Installing core pkg tools…"
pkg install -y \
  nmap netcat-openbsd openssh curl wget git vim \
  hydra hashcat sqlmap john metasploit \
  net-tools tcpdump tshark dnsutils whois dsniff \
  aircrack-ng responder ike-scan snmp \
  binutils clang gcc make perl python python2 ruby \
  php golang rust rustc cargo \
  neofetch tmux htop figlet cowsay

echo -e "\n[*] Installing Python tools via pip…"
pip install --no-cache-dir \
  impacket pwntools scapy recon-ng theHarvester \
  sublist3r massdns urllib3 requests grequests \
  cloudscraper bleach python-nmap wordlists \
  ldap3 xmltodict

echo -e "\n[*] Installing Ruby tools via gem…"
gem install --no-document \
  wpscan patator evilginx2 metasploit-framework \
  dirhunt proxifier

echo -e "\n[*] Installing Node.js tools via npm…"
npm install -g --no-fund --no-audit \
  httpx subfinder nuclei ffuf dirsearch \
  eyewitness dalfox wappalyzer-cli whatweb

echo -e "\n[*] Installing Go‑based tools…"
export GOPATH="$HOME/go"
mkdir -p "$GOPATH/bin"
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
go install github.com/projectdiscovery/chaos-client/cmd/chaos@latest
go install github.com/tomnomnom/httprobe@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/tomnomnom/gf@latest
go install github.com/jaeles-project/gospider@latest
echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.bashrc

echo -e "\n[*] Installing Rust‑based tools via cargo…"
cargo install \
  rustscan altdns grex cargo-tarpaulin

echo -e "\n[*] Cloning & setting up Git‑based frameworks…"
cd "$HOME"
git clone --depth=1 https://github.com/PortSwigger/burp_suite_community.git burp
git clone --depth=1 https://github.com/kgretzky/evilginx2.git evilginx2
git clone --depth=1 https://github.com/Veil-Framework/Veil.git veil && cd veil && ./Install.sh -c && cd "$HOME"
git clone --depth=1 https://github.com/OSCP-Tools/AutoRecon.git autorecon
git clone --depth=1 https://github.com/SecureAuthCorp/impacket.git && cd impacket && pip install . && cd "$HOME"
git clone --depth=1 https://github.com/PowerShellMafia/PowerSploit.git
git clone --depth=1 https://github.com/Greenwolf/Responder.git responder.py

echo -e "\n[*] Cleanup APT caches…"
apt clean && apt autoclean

echo -e "\n✅ Ultimate Kali‑style toolset installed!"

# 4) Configure banner & prompt in ~/.bashrc
echo -e "\n[*] Configuring 'Welcome to kali' banner in $BASHRC…"
grep -q "WELCOME_TO_KALI" "$BASHRC" || cat >> "$BASHRC" <<'EOF'

# --- WELCOME_TO_KALI START ---
clear
echo -e "\e[1;31m"
echo "  _    _      _ _        __        __         _     _ "
echo " | |  | |    | | |       \ \\      / /        | |   | |"
echo " | |__| | ___| | | ___    \ \\ /\ / /__  _ __ | | __| |"
echo " |  __  |/ _ \\ | |/ _ \\    \ V  V / _ \\| '_ \\| |/ _\` |"
echo " | |  | |  __/ | | (_) |    | | | (_) | | | | | (_| |"
echo " |_|  |_|\\___|_|_|\\___( )   |_|  \\___/|_| |_|_|\\__,_|"
echo "                     |/        "
echo -e "\e[0m"
echo -e "\e[1;33mWelcome to kali!\e[0m"
PS1="\[\e[31m\]\u@kali:\w# \[\e[0m\]"
# --- WELCOME_TO_KALI END ---
EOF

echo -e "\n🎉 Done! Restart Termux to see the new banner and start hacking.\n"
