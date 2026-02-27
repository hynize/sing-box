#!/bin/bash
# Small-Hacker Sing-box Master v2.1 (Fixed for Remote Execution)
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BASE_URL="https://raw.githubusercontent.com/hynize/sing-box/main"

[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 必须使用 root 运行。${NC}" && exit 1

show_menu() {
    clear
    echo -e "${CYAN}Small-Hacker Sing-box Master v2.1 👾${NC}"
    echo "1. Install Argo + Hysteria2 (Brute Force)"
    echo "2. Install Argo + TUIC v5    (Fast Response)"
    echo "3. Uninstall & Cleanup"
    echo "4. Exit"
    echo -e "${BLUE}------------------------------------------------${NC}"
    read -p "Option [1-4]: " choice < /dev/tty
}

show_menu

# 在这里动态下载核心组件
case $choice in
    1|2)
        echo -e "${BLUE}正在拉取战神版核心组件...${NC}"
        mkdir -p lib
        curl -sL "${BASE_URL}/lib/core.sh" -o lib/core.sh
        curl -sL "${BASE_URL}/install_vless_udp.sh" -o install_vless_udp.sh
        chmod +x install_vless_udp.sh
        
        if [ "$choice" == "1" ]; then
            ./install_vless_udp.sh hy2
        else
            ./install_vless_udp.sh tuic
        fi
        ;;
    3)
        echo -e "${YELLOW}正在拉取清理脚本...${NC}"
        mkdir -p lib
        curl -sL "${BASE_URL}/lib/core.sh" -o lib/core.sh
        # 直接调用 core 中的 cleanup
        source ./lib/core.sh
        cleanup
        ;;
    *)
        exit 0
        ;;
esac
