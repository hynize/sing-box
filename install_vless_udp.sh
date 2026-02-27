#!/bin/bash
# Improved Installer - Modular & Stabilized
source ./lib/core.sh

MODE=$1 # 'hy2' or 'tuic'
[[ -z $MODE ]] && echo "Usage: $0 [hy2|tuic]" && exit 1

init_dirs
download_components
generate_certs

# Inputs
read -p "Argo Mode (1.Temp 2.Fixed): " am < /dev/tty
if [ "$am" == "2" ]; then 
    read -p "Token: " tk < /dev/tty; read -p "Domain: " dm < /dev/tty
    echo "$tk" > "$WORKDIR/argo_token.txt"; echo "$dm" > "$WORKDIR/argo_domain.txt"
fi
read -p "Vless Local Port: " vp < /dev/tty; [ -z "$vp" ] && vp=$(shuf -i 10000-20000 -n 1)
read -p "UDP Port (Hy2/Tuic): " up < /dev/tty; [ -z "$up" ] && up=$(shuf -i 20000-60000 -n 1)
uuid=$(cat /proc/sys/kernel/random/uuid); pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
path="/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)"

# Build Config
if [[ "$MODE" == "hy2" ]]; then
    UDP_JSON='{ "type": "hysteria2", "tag": "hy2-in", "listen": "::", "listen_port": '$up', "users": [{ "password": "'$pass'" }], "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
else
    UDP_JSON='{ "type": "tuic", "tag": "tuic-in", "listen": "::", "listen_port": '$up', "users": [{ "uuid": "'$uuid'", "password": "'$pass'" }], "congestion_control": "bbr", "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
fi

cat > "$CONFIG_FILE" <<EOC
{
  "log": { "level": "error" },
  "inbounds": [
    { "type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": $vp, "users": [{ "uuid": "$uuid" }], "transport": { "type": "ws", "path": "$path" } },
    $UDP_JSON
  ],
  "outbounds": [{ "type": "direct" }]
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

# Link Gen
echo -e "\n${GREEN}=== Deployment Success ===${NC}"
IP=$(curl -s ifconfig.me); PREF="saas.sin.fan"
ARGO_DM=$(cat "$WORKDIR/argo_domain.txt" 2>/dev/null)
if [ -z "$ARGO_DM" ]; then
    echo -e "${YELLOW}Waiting for Argo domain...${NC}"; sleep 10
    ARGO_DM=$(sudo journalctl -u cyber-argo --no-hostname -n 50 | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' | tail -1 | sed 's#https://##')
fi

echo -e "${CYAN}[1] Vless+Argo:${NC} vless://${uuid}@${PREF}:443?encryption=none&security=tls&sni=${ARGO_DM}&host=${ARGO_DM}&type=ws&path=${path}#Argo"
if [[ "$MODE" == "hy2" ]]; then
    echo -e "${CYAN}[2] Hysteria2:${NC} hysteria2://${pass}@${IP}:${up}?sni=www.bing.com&insecure=1#Hy2"
else
    echo -e "${CYAN}[2] TUIC v5:${NC} tuic://${uuid}:${pass}@${IP}:${up}?sni=www.bing.com&alpn=h3&congestion_control=bbr&allow_insecure=1#Tuic"
fi
