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

cat > "$CONFIG_FILE" <<EOF
{
  "log": { "level": "error" },
  "inbounds": [
    { "type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": $vp, "users": [{ "uuid": "$uuid" }], "transport": { "type": "ws", "path": "$path" } },
    $UDP_JSON
  ],
  "outbounds": [{ "type": "direct" }]
}
