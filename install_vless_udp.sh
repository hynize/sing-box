#!/bin/bash
# Small-Hacker War-God Edition - Vless+Argo+UDP
source ./lib/core.sh

MODE=$1 # 'hy2' or 'tuic'
[[ -z $MODE ]] && echo "Usage: $0 [hy2|tuic]" && exit 1

pre_audit
init_dirs
download_components
generate_certs

# Inputs
echo -e "${CYAN}--- Configuration Panel ---${NC}"
read -p "Argo Mode (1.Temp 2.Fixed): " am < /dev/tty
if [ "$am" == "2" ]; then 
    read -p "Token: " tk < /dev/tty; read -p "Domain: " dm < /dev/tty
    echo "$tk" > "$WORKDIR/argo_token.txt"; echo "$dm" > "$WORKDIR/argo_domain.txt"
fi
read -p "Vless Local Port [Random]: " vp < /dev/tty; [ -z "$vp" ] && vp=$(shuf -i 10000-20000 -n 1)
read -p "UDP Port [Random]: " up < /dev/tty; [ -z "$up" ] && up=$(shuf -i 20000-60000 -n 1)
uuid=$(cat /proc/sys/kernel/random/uuid); pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
path="/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)"

# Build Config with Sniffer & Route
if [[ "$MODE" == "hy2" ]]; then
    UDP_JSON='{ "type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": '$up', "users": [{ "password": "'$pass'" }], "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
else
    UDP_JSON='{ "type": "tuic", "tag": "tuic-in", "listen": "::", "listen_port": '$up', "users": [{ "uuid": "'$uuid'", "password": "'$pass'" }], "congestion_control": "bbr", "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
fi

cat > "$CONFIG_FILE" <<EOC
{
  "log": { "level": "error" },
  "inbounds": [
    { "type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": $vp, "users": [{ "uuid": "$uuid" }], "transport": { "type": "ws", "path": "$path" }, "sniff": true, "sniff_override_destination": true },
    $UDP_JSON
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "block" }
  ],
  "route": {
    "rules": [
      { "port": [25, 465, 587], "outbound": "block" },
      { "protocol": "dns", "outbound": "direct" }
    ]
  }
}
EOC

# Save state
echo "$uuid" > "$WORKDIR/uuid.txt"; echo "$path" > "$WORKDIR/path.txt"; echo "$pass" > "$WORKDIR/pass.txt"; echo "$up" > "$WORKDIR/up.txt"; echo "$vp" > "$WORKDIR/vp.txt"

# Services
setup_systemd "cyber-sb" "$SB_BINARY run -c $CONFIG_FILE" "Cyber Sing-box"
argo_token=$(cat "$WORKDIR/argo_token.txt" 2>/dev/null)
if [ -n "$argo_token" ]; then
    setup_systemd "cyber-argo" "$CF_BINARY tunnel run --token $argo_token" "Cyber Argo"
else
    setup_systemd "cyber-argo" "$CF_BINARY tunnel --url http://127.0.0.1:$vp" "Cyber Argo"
fi

# Link Gen & Bento UI
clear
echo -e "${CYAN}┌────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│        Small-Hacker Sing-box War-God Edition 👾        │${NC}"
echo -e "${CYAN}└────────────────────────────────────────────────────────┘${NC}"

IP=$(curl -s ifconfig.me); PREF="saas.sin.fan"
ARGO_DM=$(cat "$WORKDIR/argo_domain.txt" 2>/dev/null)
if [ -z "$ARGO_DM" ]; then
    echo -e "${YELLOW}Wait... Sniffing Argo Domain (10s)${NC}"; sleep 10
    ARGO_DM=$(sudo journalctl -u cyber-argo --no-hostname -n 50 | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' | tail -1 | sed 's#https://##')
fi

echo -e "${BLUE} [Bento: Baseline]${NC}"
echo -e "  UUID:   ${GREEN}$uuid${NC}"
echo -e "  Path:   ${GREEN}$path${NC}"
echo -e "  Argo:   ${GREEN}$ARGO_DM${NC}"

VLESS_LINK="vless://${uuid}@${PREF}:443?encryption=none&security=tls&sni=${ARGO_DM}&host=${ARGO_DM}&type=ws&path=${path}#Argo_WarGod"
if [[ "$MODE" == "hy2" ]]; then
    UDP_LINK="hysteria2://${pass}@${IP}:${up}?sni=www.bing.com&insecure=1#Hy2_WarGod"
    echo -e "\n${BLUE} [Bento: Brute Force - Hysteria2]${NC}"
    echo -e "  Pass:   ${GREEN}$pass${NC}"
    echo -e "  Port:   ${GREEN}$up${NC}"
else
    UDP_LINK="tuic://${uuid}:${pass}@${IP}:${up}?sni=www.bing.com&alpn=h3&congestion_control=bbr&allow_insecure=1#Tuic_WarGod"
    echo -e "\n${BLUE} [Bento: Fast Response - TUIC v5]${NC}"
    echo -e "  Pass:   ${GREEN}$pass${NC}"
    echo -e "  Port:   ${GREEN}$up${NC}"
fi

echo -e "\n${CYAN}--- Links ---${NC}"
echo -e "${YELLOW}VLESS:${NC} $VLESS_LINK"
echo -e "${YELLOW}UDP:  ${NC} $UDP_LINK"

# Local Sub (Simulated)
echo -e "\n${MAGENTA}Sub Link (Base64):${NC}"
echo -e "$VLESS_LINK\n$UDP_LINK" | base64 | tr -d '\n' && echo -e "\n"
