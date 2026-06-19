#!/bin/bash

handle_signal() {  
    echo "Received signal, exiting..."  
    exit 0  
}  
  
# 捕获SIGTERM信号  
trap handle_signal SIGTERM  

# 判断是否设置代理，设置代理后容器启动时更新配置文件
if [ -n "$PROXY" ]; then  
    cp /etc/proxychains/proxychains.conf /etc/proxysock5.conf
    sed -i "s/^socks4 	127.0.0.1 9050/${PROXY}/" "/etc/proxysock5.conf"  
fi  

# 循环执行
while [ 1 -eq 1 ]
do
    # 判断是否设置代理
    if [ -n "$PROXY" ]; then  
        proxychains -q -f /etc/proxysock5.conf /bin/bash namesiloddns-dk.sh
    else  
        /bin/bash namesiloddns-dk.sh
    fi
    sleep ${LOOPTIME:-15}m
done