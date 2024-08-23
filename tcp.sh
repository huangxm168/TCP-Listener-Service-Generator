#!/bin/bash

# 清除屏幕内容
clear

# 颜色定义
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[93m"
BLUE="\e[34m"
CYAN="\e[36m"     # 青色
MAGENTA="\e[35m"  # 洋红色
RESET="\e[0m"

# 打印欢迎横幅
echo ""
echo -e "--- Welcome to the TCP Listener Service Generator for Uptime Kuma ---"
echo ""
echo ""
echo ""
echo -e " █████   █████  ███         █████   █████ █████ █████ ██████   ██████
░░███   ░░███  ░░░         ░░███   ░░███ ░░███ ░░███ ░░██████ ██████ 
 ░███    ░███  ████         ░███    ░███  ░░███ ███   ░███░█████░███ 
 ░███████████ ░░███         ░███████████   ░░█████    ░███░░███ ░███ 
 ░███░░░░░███  ░███         ░███░░░░░███    ███░███   ░███ ░░░  ░███ 
 ░███    ░███  ░███         ░███    ░███   ███ ░░███  ░███      ░███ 
 █████   █████ █████  ██    █████   █████ █████ █████ █████     █████
░░░░░   ░░░░░ ░░░░░  ██    ░░░░░   ░░░░░ ░░░░░ ░░░░░ ░░░░░     ░░░░░ 
                    ░░                                               
                                                                     
                                                                     "
echo -e "---------- 欢迎使用 TCP 监听服务生成器脚本 for Uptime Kuma ----------"

# 检测是否以 root 用户或具有 sudo 权限的用户运行脚本
if [ "$EUID" -ne 0 ]; then
    echo ""
    echo -e "${RED}检测到当前用户非 root 用户，或没有使用 sudo 命令运行脚本！${RESET}"
    echo ""
    echo -e "${YELLOW}请切换为 root 用户或使用 sudo 命令运行该脚本。${RESET}"
    echo ""
    echo -e "${MAGENTA}脚本已自动退出。${RESET}"
    exit 1
fi

# 系统更新和安装依赖
echo ""
echo -e "${YELLOW}正在更新系统并安装环境依赖……${RESET}"
apt-get update > /dev/null && apt-get upgrade -y > /dev/null && apt-get install socat -y  > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}系统和软件更新失败，请检查相关错误，或手动更新后再次运行脚本。${RESET}"
    echo ""
    echo -e "${MAGENTA}脚本已自动退出。${RESET}"
    exit 1
fi
echo -e "${GREEN}已成功更新系统和软件！${RESET}"

# 函数：检测输入的服务名称是否有效
validate_name() {
    local name=$1
    if [[ "$name" =~ ^[a-zA-Z0-9-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# 询问用户为服务命名
echo ""
read -p "$(echo -e "${CYAN}请为该服务命名（仅限英文、数字和短横线“-”，按下回车键来使用默认名称 uptime-kuma-tcp）：${RESET}")" service_name

# 如果用户直接按回车，则使用默认名称
if [ -z "$service_name" ]; then
    service_name="uptime-kuma-tcp"
fi

# 验证服务名称是否合法
while ! validate_name "$service_name"; do
    echo -e "${RED}服务名称无效。请仅使用英文、数字和短横线“-”。${RESET}"
    echo ""
    read -p "$(echo -e "${CYAN}请重新为该服务命名：${RESET}")" service_name
    if [ -z "$service_name" ];then
        service_name="uptime-kuma-tcp"
    fi
done

echo -e "${GREEN}服务名称已成功设置为: $service_name${RESET}"

# 函数：检测端口是否被占用
check_port() {
    local port=$1
    if ss -lntu | grep -q ":$port "; then
        return 1
    else
        return 0
    fi
}

# 询问用户要监听的端口
echo ""
read -p "$(echo -e "${CYAN}请输入您要监听的端口（按下回车键来使用默认端口 55555）：${RESET}")" port

# 如果用户直接按回车，则使用默认端口
if [ -z "$port" ];then
    port=55555
fi

# 检查端口是否被占用
echo ""
echo -e "${YELLOW}正在检查您指定的端口 $port 是否被占用...${RESET}"
while ! check_port "$port"; do
    echo -e "${RED}端口 $port 已经被占用。以下是当前系统正在监听的端口：${RESET}"
    ss -lntu
    echo ""
    read -p "$(echo -e "${CYAN}请重新输入您要监听的端口（按下回车键来使用默认端口 55555）：${RESET}")" port
    if [ -z "$port" ];then
        port=55555
    fi
done
echo -e "${GREEN}端口 $port 可以使用。已成功将其设定为目标监听端口！${RESET}"

# 创建 Systemd 单元文件
echo ""
echo -e "${YELLOW}正在创建 Systemd 单元文件来监听端口 $port...${RESET}"
cat <<EOL > /etc/systemd/system/$service_name.service
[Unit]
Description=$service_name TCP Listener on Port $port
After=network.target

[Service]
ExecStart=/usr/bin/socat TCP-LISTEN:$port,reuseaddr,fork EXEC:/bin/cat 
Restart=always

[Install]
WantedBy=multi-user.target
EOL
echo -e "${GREEN}Systemd 单元文件创建成功！${RESET}"

# 使 Systemd 单元生效并启动服务
echo ""
echo -e "${YELLOW}正在重新加载 Systemd 文件并启动 $service_name 服务...${RESET}"
systemctl daemon-reload
systemctl start "$service_name"
systemctl enable "$service_name"
echo -e "${GREEN}$service_name 服务已启动并设置为开机自启。${RESET}"

# 验证服务状态
echo ""
echo -e "${YELLOW}正在检查 $service_name 服务的运行状态...${RESET}"
if systemctl status "$service_name" | grep -q "Active: active (running)"; then
    echo -e "${GREEN}$service_name 已成功运行！${RESET}"
    service_status="success"
else
    echo -e "${RED}$service_name 服务运行失败。您可以根据脚本运行结束时的提示来检查日志中的错误信息。${RESET}"
    service_status="failure"
fi

# 设置防火墙放行端口
echo ""
echo -e "${YELLOW}正在检测防火墙配置及运行状态...${RESET}"

# 检测防火墙工具
ufw_installed=false
firewalld_installed=false
iptables_installed=false
nftables_installed=false

# 检查各个防火墙工具是否安装
if dpkg -l | grep -q ufw; then
    echo -e "${BLUE}检测到 ufw 已安装。${RESET}"
    ufw_installed=true
fi

if dpkg -l | grep -q firewalld; then
    echo -e "${BLUE}检测到 firewalld 已安装。${RESET}"
    firewalld_installed=true
fi

if dpkg -l | grep -q iptables; then
    echo -e "${BLUE}检测到 iptables 已安装。${RESET}"
    iptables_installed=true
fi

if dpkg -l | grep -q nftables; then
    echo -e "${BLUE}检测到 nftables 已安装。${RESET}"
    nftables_installed=true
fi

# 根据检测结果选择防火墙工具
if $ufw_installed && $iptables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    ufw allow "$port"/tcp > /dev/null 2>&1 && ufw reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 ufw 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $ufw_installed && $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    ufw allow "$port"/tcp > /dev/null 2>&1 && ufw reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 ufw 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $ufw_installed && $iptables_installed && $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    ufw allow "$port"/tcp > /dev/null 2>&1 && ufw reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 ufw 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $iptables_installed && ! $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    sudo ./ufw.sh > /dev/null
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功安装 ufw 并通过其配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $nftables_installed && ! $iptables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    sudo ./ufw.sh > /dev/null
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功安装 ufw 并通过其配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $iptables_installed && $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    sudo ./ufw.sh > /dev/null
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功安装 ufw 并通过其配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $firewalld_installed && $iptables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    firewall-cmd --add-port="$port"/tcp --permanent > /dev/null 2>&1 && firewall-cmd --reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 firewalld 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $firewalld_installed && $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    firewall-cmd --add-port="$port"/tcp --permanent > /dev/null 2>&1 && firewall-cmd --reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 firewalld 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif $firewalld_installed && $iptables_installed && $nftables_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    firewall-cmd --add-port="$port"/tcp --permanent > /dev/null 2>&1 && firewall-cmd --reload > /dev/null 2>&1
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功通过 firewalld 配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
elif ! $ufw_installed && ! $nftables_installed && ! $iptables_installed && ! $firewalld_installed; then
    echo ""
    echo -e "${YELLOW}正在放行端口 $port...${RESET}"
    sudo ./ufw.sh > /dev/null
    echo -e "${GREEN}根据当前系统的防火墙运行状态，已成功安装 ufw 并通过其配置防火墙，允许端口 $port 的 TCP 入站流量。${RESET}"
else
    echo -e "${RED}没有检测到合适的防火墙或防火墙配置，请您自行操作来放行端口。${RESET}"
fi

# 最终输出，根据服务状态判断
if [ "$service_status" = "success" ]; then
    echo ""
    echo -e "${GREEN}Success!"
    echo -e "${GREEN}已成功完成全部配置！现在 $service_name 服务已在监听端口 $port。${RESET}"
else
    echo ""
    echo -e "${RED}Attention!"
    echo -e "${RED}由于 $service_name 服务没有成功运行，已为您调取相关日志，请根据输出内容进行排查：${RESET}"
    journalctl -u "$service_name" --no-pager -n 20
fi
