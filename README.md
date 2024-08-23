# TCP 监听服务脚本生成器 for Uptime Kuma

**一键命令**

    wget --no-check-certificate -O tcp.sh https://raw.githubusercontent.com/huangxm168/TCP-Listener-Service-Generator/main/tcp.sh && wget --no-check-certificate -O ufw.sh https://raw.githubusercontent.com/huangxm168/UFW-Allow-Listening-Ports-Automation/main/ufw.sh && chmod +x tcp.sh ufw.sh && sudo ./tcp.sh

**脚本功能概述：**

该脚本自动化地设置一个基于 socat 的 TCP 监听服务，允许用户自定义服务名称和监听端口，并自动配置防火墙以放行指定端口。

**运行流程逻辑：**

1. 服务命名：设定服务名称或使用默认名称
2. 端口选择和验证：设定监听端口或使用默认端口，验证端口是否被占用
3. 服务配置：生成并启动一个 Systemd 持久化服务以监听设定的端口
4. 服务状态检查：检查服务是否成功运行，并根据结果输出相应信息
5. 防火墙配置：根据系统中安装的防火墙工具自动配置端口放行规则

**脚本运行要求**

- 已安装 wget
- root 用户或使用 sudo 命令

**已验证系统**

- [x] Debian 11
- [x] Debian 12
