#!/bin/bash
# Small-Hacker Core Library - Modular Proxy Management
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
WORKDIR="$HOME/.cyber-proxy"; BIN_DIR="$WORKDIR/bin"; CONFIG_FILE="$WORKDIR/config.json"
SB_BINARY="$BIN_DIR/sing-box"; CF_BINARY="$BIN_DIR/cloudflared"; CERT_DIR="$WORKDIR/cert"

get_arch() { case "$(uname -m)" in x86_64) echo "amd64" ;; aarch64|arm64) echo "arm64" ;; *) echo "unknown" ;; esac; }

init_dirs() { mkdir -p "$BIN_DIR" "$CERT_DIR"; }

download_components() {
    local ARCH=$(get_arch)
    [[ "$ARCH" == "unknown" ]] && echo -e "${RED}Unsupported Arch${NC}" && exit 1
    if [ ! -f "$SB_BINARY" ]; then
        echo -e "${BLUE}Downloading Sing-box...${NC}"
        local LATEST_SB=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
        curl -L "https://github.com/SagerNet/sing-box/releases/download/v${LATEST_SB}/sing-box-${LATEST_SB}-linux-${ARCH}.tar.gz" -o /tmp/sb.tar.gz
        tar -xzf /tmp/sb.tar.gz -C /tmp && find /tmp -name "sing-box" -type f -exec mv {} "$SB_BINARY" \; && chmod +x "$SB_BINARY"
    fi
    if [ ! -f "$CF_BINARY" ]; then
        echo -e "${BLUE}Downloading Cloudflared...${NC}"
        curl -L "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}" -o "$CF_BINARY" && chmod +x "$CF_BINARY"
    fi
}

generate_certs() {
    local sni=${1:-www.bing.com}
    if [[ ! -f "$CERT_DIR/cert.pem" ]]; then
        openssl req -x509 -nodes -newkey rsa:2048 -keyout "$CERT_DIR/privkey.pem" -out "$CERT_DIR/cert.pem" -days 3650 -subj "/CN=$sni" 2>/dev/null
    fi
}

setup_systemd() {
    local service_name=$1; local cmd=$2; local desc=$3
    sudo tee /etc/systemd/system/${service_name}.service > /dev/null <<EOT
[Unit]
Description=$desc
After=network.target
[Service]
ExecStart=$cmd
Restart=always
User=$(whoami)
WorkingDirectory=$WORKDIR
[Install]
WantedBy=multi-user.target
EOT
    sudo systemctl daemon-reload && sudo systemctl enable --now ${service_name}
}

cleanup() {
    sudo systemctl disable --now cyber-sb cyber-argo 2>/dev/null || true
    rm -rf "$WORKDIR"
    sudo rm -f /etc/systemd/system/cyber-sb.service /etc/systemd/system/cyber-argo.service
    sudo systemctl daemon-reload
    echo -e "${GREEN}Cleanup complete.${NC}"
}
