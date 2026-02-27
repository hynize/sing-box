#!/bin/bash
source ./lib/core.sh
set -e
[[ $EUID -ne 0 ]] && echo "Run as root" && exit 1

show_menu() {
    clear
    echo -e "${CYAN}Small-Hacker Sing-box Master v2.0 👾${NC}"
    echo "1. Install Argo + Hysteria2 (Brute Force)"
    echo "2. Install Argo + TUIC v5    (Fast Response)"
    echo "3. Uninstall & Cleanup"
    echo "4. Exit"
    read -p "Option [1-4]: " choice < /dev/tty
}

show_menu
case $choice in
    1) chmod +x install_vless_udp.sh && ./install_vless_udp.sh hy2 ;;
    2) chmod +x install_vless_udp.sh && ./install_vless_udp.sh tuic ;;
    3) cleanup ;;
    *) exit 0 ;;
esac
