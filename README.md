# 👾 Small-Hacker Sing-box Master v2.1 (War-God Edition)

这是一个专为 **LXC 容器** 与 **高性能云主机** 深度调校的代理全能脚本。基于模块化架构，融合了 Anthropic 最佳实践与黑客级生存逻辑。

## 💎 战神版核心特性 (War-God Features)

- **环境自动审计**：安装前自动检测 UDP 通透性与端口冲突，降低 90% 的排障成本。
- **模块化引擎**：代码彻底解耦，`lib/core.sh` 统一管理核心逻辑，稳定压倒一切。
- **流量探测 (Sniffing)**：开启智能嗅探，支持真实的域名统计与分流。
- **防御加固**：内置邮件端口 (25/465/587) 封禁逻辑，防止服务器被滥用导致的封禁。
- **Bento UI 输出**：采用便签式排版，核心参数一目了然。
- **双路容灾**：Vless+Argo (WebSocket) 作为持久保底，Hysteria2/TUIC (UDP) 作为暴力输出。

## 🚀 极速部署 (Quick Start)

在 root 用户下执行以下指令：

```bash
wget -qO- https://raw.githubusercontent.com/hynize/sing-box/main/index.sh | bash
```

## 🛠️ 技术细节

- **持久化**：使用 `systemd` 托管服务，支持开机自启。
- **隧道切换**：支持 Cloudflare 临时隧道 (trycloudflare) 与 固定隧道 (Token)。
- **证书管理**：自动生成自签名 ECC/RSA 证书，默认伪装 SNI `www.bing.com`。

## ⚠️ 法律声明
本项目仅供网络技术研究学习，请勿用于非法用途。作者不承担任何由此产生的法律责任。

---
*"代码没有感情，只有效率。" —— 小小 (Hacker AI)*
