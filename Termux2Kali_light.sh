#!/usr/bin/env bash
#
# Termux2Kali_ultra_light.sh
# Most-comprehensive Kali‑style installer in pure Termux (no chroot)
# Mixes pkg, pip, gem, npm, go, cargo & git.
#
# Usage: bash Termux2Kali_ultra_light.sh

set -euo pipefail
IFS=$'\n\t'
BASHRC="$HOME/.bashrc"

echo -e "\n[*] Updating Termux & enabling repos…"
pkg update -y && pkg upgrade -y
pkg install -y unstable-repo root-repo || true

echo -e "\n[*] Installing available core pkg tools…"
CORE_PKG=(nmap netcat-openbsd openssh curl wget git vim \
          neofetch tmux htop figlet cowsay python python2 \
          nodejs golang rust)
for p in "${CORE_PKG[@]}"; do
  pkg install -y "$p" || echo "[!] pkg: $p not found, skipping"
done

echo -e "\n[*] Installing Python tools via pip…"
PY_TOOLS=(sqlmap impacket pwntools scapy theHarvester \
          sublist3r masscan python-nmap wordlists \
          requests beautifulsoup4)
for t in "${PY_TOOLS[@]}"; do
  pip install --no-cache-dir "$t" || echo "[!] pip: $t failed"
done

echo -e "\n[*] Installing Ruby tools via gem…"
GEM_TOOLS=(wpscan patator)
for g in "${GEM_TOOLS[@]}"; do
  gem install --no-document "$g" || echo "[!] gem: $g failed"
done

echo -e "\n[*] Installing Node.js tools via npm…"
NPM_TOOLS=(httpx subfinder nuclei ffuf dirsearch \
           eyewitness dalfox wappalyzer-cli)
for n in "${NPM_TOOLS[@]}"; do
  npm install -g --no-fund --no-audit "$n" || echo "[!] npm: $n failed"
done

echo -e "\n[*] Installing Go‑based tools…"
export GOPATH="$HOME/go"
mkdir -p "$GOPATH/bin"
GO_TOOLS=(
  github.com/projectdiscovery/subfinder/v2/cmd/subfinder
  github.com/projectdiscovery/httpx/cmd/httpx
  github.com/projectdiscovery/naabu/v2/cmd/naabu
  github.com/projectdiscovery/nuclei/v2/cmd/nuclei
  github.com/tomnomnom/httprobe
)
for pkg_path in "${GO_TOOLS[@]}"; do
  go install "$pkg_path@latest" || echo "[!] go: $pkg_path failed"
done
echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.bashrc

echo -e "\n[*] Installing Rust‑based tools via cargo…"
CARGO_TOOLS=(rustscan altdns grex)
for c in "${CARGO_TOOLS[@]}"; do
  cargo install "$c" || echo "[!] cargo: $c failed"
done

echo -e "\n[*] Cloning & setting up key Git‑based tools…"
cd "$HOME"
# Burp Suite community (Java GUI—needs Java, may skip)
git clone --depth=1 https://github.com/PortSwigger/burp_suite_community.git burp || true
# Evilginx2 (may require Linux kernel features; likely non‑functional)
git clone --depth=1 https://github.com/kgretzky/evilginx2.git || true
# AutoRecon (Python)
git clone --depth=1 https://github.com/OSCP-Tools/AutoRecon.git autorecon && \
  cd autorecon && pip install . && cd "$HOME" || true

echo -e "\n[*] Cleanup…"
pkg clean || true

echo -e "\n✅ Installed Kali‑style tools in pure Termux!"
echo -e "Try some commands:\n  nmap --version\n  sqlmap --help\n  subfinder -h\n  httpx -h\n  rustscan --help\n"

# Configure Welcome banner in ~/.bashrc
if ! grep -q "WELCOME_TO_KALI" "$BASHRC"; then
  echo -e "\n[*] Adding Welcome banner to ~/.bashrc…"
  cat >> "$BASHRC" <<'EOF'

# --- WELCOME_TO_KALI START ---
clear
echo -e "\e[1;31mWelcome to kali\e[0m"
PS1="\[\e[31m\]\u@kali:\w# \[\e[0m\]"
# --- WELCOME_TO_KALI END ---
EOF
fi

echo -e "\n🎉 Done! Restart Termux to see banner and use tools."
