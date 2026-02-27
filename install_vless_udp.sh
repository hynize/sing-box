#!/bin/bash
# 小小战神版 v2.2.2 - 逻辑修正与 Reality 优化
source ./lib/core.sh

MODE=$1 # 'hy2', 'tuic', 'reality'
[[ -z $MODE ]] && echo "用法: $0 [hy2|tuic|reality]" && exit 1

pre_audit
init_dirs
download_components

# 输入面板
echo -e "${CYAN}--- 配置面板 ---${NC}"

if [[ "$MODE" != "reality" ]]; then
    read -p "Argo 模式 (1.临时隧道 2.固定 Token): " am < /dev/tty
    if [ "$am" == "2" ]; then 
        read -p "请输入 Token: " tk < /dev/tty; read -p "请输入解析好的域名: " dm < /dev/tty
        echo "$tk" > "$WORKDIR/argo_token.txt"; echo "$dm" > "$WORKDIR/argo_domain.txt"
    fi
    read -p "Vless 本地端口 [默认随机]: " vp < /dev/tty; [ -z "$vp" ] && vp=$(shuf -i 10000-20000 -n 1)
    read -p "UDP 端口 (Hy2/Tuic) [默认随机]: " up < /dev/tty; [ -z "$up" ] && up=$(shuf -i 20000-60000 -n 1)
else
    # 随机选择伪装域名
    domains=("www.microsoft.com" "azure.microsoft.com" "www.apple.com" "swscan.apple.com" "www.intel.com" "www.debian.org" "www.docker.com" "www.hulu.com" "www.disneyplus.com" "www.amazon.com" "aws.amazon.com" "www.oracle.com" "www.jpmorganchase.com" "www.americanexpress.com" "images.apple.com" "www.samsung.com" "www.nvidia.com" "www.ikea.com" "www.sony.com" "www.toyota.com" "www.nintendo.co.jp" "www.hsbc.com" "www.cathaypacific.com" "www.hkex.com.hk")
    random_domain=${domains[$RANDOM % ${#domains[@]}]}
    
    read -p "Reality 监听端口 [默认 443]: " rp < /dev/tty; [ -z "$rp" ] && rp=443
    read -p "Reality 目标地址 [默认 $random_domain:443]: " rd < /dev/tty; [ -z "$rd" ] && rd="$random_domain:443"
fi

uuid=$(cat /proc/sys/kernel/random/uuid); pass=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24)
path="/$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 12)"

# 构建 Inbound 配置
if [[ "$MODE" == "reality" ]]; then
    # 生成 Reality 密钥
    key_pair=$($SB_BINARY generate x25519)
    priv_key=$(echo "$key_pair" | grep "Private key" | awk '{print $3}')
    pub_key=$(echo "$key_pair" | grep "Public key" | awk '{print $3}')
    short_id=$(openssl rand -hex 8)
    sni=$(echo $rd | cut -d: -f1)
    
    # 强制监听 0.0.0.0 避免 IPv6 绑定失败导致的连通性问题
    INBOUND_JSON='{
      "type": "vless", "tag": "vless-reality-in", "listen": "0.0.0.0", "listen_port": '$rp',
      "users": [{ "uuid": "'$uuid'", "flow": "xtls-rprx-vision" }],
      "tls": {
        "enabled": true, "server_name": "'$sni'", "reality": {
          "enabled": true, "handshake": { "server": "'$sni'", "server_port": 443 },
          "private_key": "'$priv_key'", "short_id": ["'$short_id'"]
        }
      }
    }'
else
    generate_certs
    if [[ "$MODE" == "hy2" ]]; then
        UDP_JSON='{ "type": "hysteria2", "tag": "hy2-in", "listen": "0.0.0.0", "listen_port": '$up', "users": [{ "password": "'$pass'" }], "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
    else
        UDP_JSON='{ "type": "tuic", "tag": "tuic-in", "listen": "0.0.0.0", "listen_port": '$up', "users": [{ "uuid": "'$uuid'", "password": "'$pass'" }], "congestion_control": "bbr", "tls": { "enabled": true, "certificate_path": "'$CERT_DIR'/cert.pem", "key_path": "'$CERT_DIR'/privkey.pem", "alpn": ["h3"] } }'
    fi
    INBOUND_JSON='{ "type": "vless", "tag": "vless-in", "listen": "127.0.0.1", "listen_port": '$vp', "users": [{ "uuid": "'$uuid'" }], "transport": { "type": "ws", "path": "'$path'" }, "sniff": true, "sniff_override_destination": true }, '$UDP_JSON
fi

# 写入配置文件
cat > "$CONFIG_FILE" <<EOC
{
  "log": { "level": "error" },
  "inbounds": [ $INBOUND_JSON ],
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

# 保存状态
echo "$uuid" > "$WORKDIR/uuid.txt"; echo "$path" > "$WORKDIR/path.txt"; echo "$pass" > "$WORKDIR/pass.txt"; echo "$up" > "$WORKDIR/up.txt"; echo "$vp" > "$WORKDIR/vp.txt"

# 启动服务
setup_systemd "cyber-sb" "$SB_BINARY run -c $CONFIG_FILE" "Cyber Sing-box"

if [[ "$MODE" != "reality" ]]; then
    argo_token=$(cat "$WORKDIR/argo_token.txt" 2>/dev/null)
    if [ -n "$argo_token" ]; then
        setup_systemd "cyber-argo" "$CF_BINARY tunnel run --token $argo_token" "Cyber Argo"
    else
        setup_systemd "cyber-argo" "$CF_BINARY tunnel --url http://127.0.0.1:$vp" "Cyber Argo"
    fi
fi

# 链接生成与 Bento UI
clear
echo -e "${CYAN}┌────────────────────────────────────────────────────────┐${NC}"
echo -e "${CYAN}│          小小 Sing-box 战神版 v2.2.2 (修正版)        │${NC}"
echo -e "${CYAN}└────────────────────────────────────────────────────────┘${NC}"

IP=$(curl -s ifconfig.me)
if [[ "$MODE" == "reality" ]]; then
    echo -e "${BLUE} [基准信息: Reality]${NC}"
    echo -e "  端口:   ${GREEN}$rp${NC}"
    echo -e "  SNI:    ${GREEN}$sni${NC}"
    REALITY_LINK="vless://${uuid}@${IP}:${rp}?encryption=none&security=reality&sni=${sni}&fp=chrome&pbk=${pub_key}&sid=${short_id}&flow=xtls-rprx-vision&type=tcp#Reality_WarGod"
    echo -e "\n${CYAN}--- 节点链接 ---${NC}"
    echo -e "${YELLOW}Reality:${NC} $REALITY_LINK"
    echo -e "\n${MAGENTA}订阅内容 (Base64):${NC}"
    echo -e "$REALITY_LINK" | base64 | tr -d '\n' && echo -e "\n"
else
    PREF="saas.sin.fan"
    ARGO_DM=$(cat "$WORKDIR/argo_domain.txt" 2>/dev/null)
    if [ -z "$ARGO_DM" ]; then
        echo -e "${YELLOW}正在嗅探 Argo 域名 (10s)...${NC}"; sleep 10
        ARGO_DM=$(sudo journalctl -u cyber-argo --no-hostname -n 50 | grep -o 'https://[a-zA-Z0-9-]*\.trycloudflare\.com' | tail -1 | sed 's#https://##')
    fi
    echo -e "${BLUE} [基准信息: Argo]${NC}"
    echo -e "  UUID:   ${GREEN}$uuid${NC}"
    echo -e "  Argo:   ${GREEN}$ARGO_DM${NC}"

    VLESS_LINK="vless://${uuid}@${PREF}:443?encryption=none&security=tls&sni=${ARGO_DM}&host=${ARGO_DM}&type=ws&path=${path}#Argo_WarGod"
    if [[ "$MODE" == "hy2" ]]; then
        UDP_LINK="hysteria2://${pass}@${IP}:${up}?sni=www.bing.com&insecure=1#Hy2_WarGod"
        echo -e "\n${BLUE} [暴力输出: Hysteria2]${NC}"
    else
        UDP_LINK="tuic://${uuid}:${pass}@${IP}:${up}?sni=www.bing.com&alpn=h3&congestion_control=bbr&allow_insecure=1#Tuic_WarGod"
        echo -e "\n${BLUE} [极速响应: TUIC v5]${NC}"
    fi
    echo -e "  密码:   ${GREEN}$pass${NC}"
    echo -e "  端口:   ${GREEN}$up${NC}"

    echo -e "\n${CYAN}--- 节点链接 ---${NC}"
    echo -e "${YELLOW}VLESS:${NC} $VLESS_LINK"
    echo -e "${YELLOW}UDP:  ${NC} $UDP_LINK"
    echo -e "\n${MAGENTA}订阅内容 (Base64):${NC}"
    echo -e "$VLESS_LINK\n$UDP_LINK" | base64 | tr -d '\n' && echo -e "\n"
fi
