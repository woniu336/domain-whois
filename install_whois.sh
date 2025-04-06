#!/bin/bash

# 检查端口占用情况的函数
check_port() {
    PORT=$1
    if lsof -i:$PORT > /dev/null; then
        echo "端口 $PORT 已被占用。"
        return 1
    else
        echo "端口 $PORT 可用。"
        return 0
    fi
}

# 安装 whois 服务的函数
install_whois() {
    echo "更新系统..."
    apt update && apt upgrade -y

    echo "安装 redis-server..."
    apt install redis-server -y

    echo "创建 whois 目录并下载 whois..."
    mkdir -p ~/whois && cd ~/whois
    wget https://github.com/KincaidYang/whois/releases/download/v0.4.1/whois_0.4.1_linux_amd64.tar.gz -O whois.tar.gz
    tar -xzf whois.tar.gz

    echo "创建配置文件 config.yaml..."
    cat <<EOL > config.yaml
redis:
  addr: "127.0.0.1:6379"
  password: ""
  db: 0
cacheexpiration: 3600
port: 8043
ratelimit: 50
proxyserver: "http://127.0.0.1:8080"
proxysuffixes: []
proxyusername: ""
proxypassword: ""
EOL

    echo "创建 systemd 服务文件..."
    cat <<EOL > /etc/systemd/system/whois.service
[Unit]
Description=whois
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/root/whois/whois
WorkingDirectory=/root/whois
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

    echo "启动并启用 whois 服务..."
    systemctl start whois
    systemctl enable whois
    echo "whois 服务安装完成！"
}

# 卸载 whois 服务的函数
uninstall_whois() {
    echo "停止并禁用 whois 服务..."
    systemctl stop whois
    systemctl disable whois
    rm -rf ~/whois
    rm -f /etc/systemd/system/whois.service
    echo "whois 服务已卸载！"
}

# 菜单
while true; do
    echo "请选择操作:"
    echo "1. 安装 whois 服务"
    echo "2. 卸载 whois 服务"
    echo "3. 退出"
    read -p "输入选项 [1-3]: " option

    case $option in
        1)
            if check_port 8043; then
                install_whois
            else
                echo "请先释放端口 8043。"
            fi
            ;;
        2)
            uninstall_whois
            ;;
        3)
            echo "退出程序。"
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择。"
            ;;
    esac
done