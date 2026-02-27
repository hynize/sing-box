#!/bin/bash
# 小小 Sing-box 战神版 v2.2 (汉化版)
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; NC='\033[0m'
BASE_URL="https://raw.githubusercontent.com/hynize/sing-box/main"

[[ $EUID -ne 0 ]] && echo -e "${RED}错误: 必须使用 root 运行。${NC}" && exit 1

show_menu() {
    clear
    echo -e "${CYAN}小小 Sing-box 战神版 v2.2 👾${NC}"
    echo "1. 安装 Argo + Hysteria2 (双路并行/暴力穿透)"
    echo "2. 安装 Argo + TUIC v5    (双路并行/极速响应)"
    echo "3. 安装 Vless + Reality   (TCP 直连/极致伪装)"
    echo "4. 彻底卸载所有代理服务"
    echo "5. 退出"
    echo -e "${BLUE}------------------------------------------------${NC}"
    read -p "请输入选项 [1-5]: " choice < /dev/tty
}

show_menu

case $choice in
    1|2|3)
        echo -e "${BLUE}正在初始化战神版工作环境...${NC}"
        rm -rf lib install_vless_udp.sh
        mkdir -p lib
        
        echo -e "${BLUE}正在拉取依赖库 [1/2]...${NC}"
        curl -sL "${BASE_URL}/lib/core.sh?v=$(date +%s)" -o lib/core.sh
        
        echo -e "${BLUE}正在拉取安装器 [2/2]...${NC}"
        curl -sL "${BASE_URL}/install_vless_udp.sh?v=$(date +%s)" -o install_vless_udp.sh
        
        chmod +x install_vless_udp.sh
        
        if [ "$choice" == "1" ]; then
            ./install_vless_udp.sh hy2
        elif [ "$choice" == "2" ]; then
            ./install_vless_udp.sh tuic
        else
            ./install_vless_udp.sh reality
        fi
        ;;
    4)
        echo -e "${YELLOW}正在执行清理程序...${NC}"
        mkdir -p lib
        curl -sL "${BASE_URL}/lib/core.sh?v=$(date +%s)" -o lib/core.sh
        source ./lib/core.sh
        cleanup
        ;;
    *)
        exit 0
        ;;
esac
