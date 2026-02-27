#!/bin/bash
# Small-Hacker Sing-box Master v2.1.1 (Force Pull Dependencies)
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BASE_URL="https://raw.githubusercontent.com/hynize/sing-box/main"

[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 必须使用 root 运行。${NC}" && exit 1

show_menu() {
    clear
    echo -e "${CYAN}Small-Hacker Sing-box Master v2.1.1 👾${NC}"
    echo "1. Install Argo + Hysteria2 (Brute Force)"
    echo "2. Install Argo + TUIC v5    (Fast Response)"
    echo "3. Uninstall & Cleanup"
    echo "4. Exit"
    echo -e "${BLUE}------------------------------------------------${NC}"
    read -p "Option [1-4]: " choice < /dev/tty
}

show_menu

case $choice in
    1|2)
        echo -e "${BLUE}正在初始化战神版工作环境...${NC}"
        # 强制清理旧的残留
        rm -rf lib install_vless_udp.sh
        mkdir -p lib
        
        echo -e "${BLUE}正在拉取依赖库 [1/2]...${NC}"
        curl -sL "${BASE_URL}/lib/core.sh?v=$(date +%s)" -o lib/core.sh
        
        echo -e "${BLUE}正在拉取安装器 [2/2]...${NC}"
        curl -sL "${BASE_URL}/install_vless_udp.sh?v=$(date +%s)" -o install_vless_udp.sh
        
        chmod +x install_vless_udp.sh
        
        if [ "$choice" == "1" ]; then
            ./install_vless_udp.sh hy2
        else
            ./install_vless_udp.sh tuic
        fi
        ;;
    3)
        echo -e "${YELLOW}正在清理...${NC}"
        mkdir -p lib
        curl -sL "${BASE_URL}/lib/core.sh?v=$(date +%s)" -o lib/core.sh
        source ./lib/core.sh
        cleanup
        ;;
    *)
        exit 0
        ;;
esac
