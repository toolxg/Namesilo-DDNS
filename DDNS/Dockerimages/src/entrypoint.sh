#!/bin/bash

handle_signal() {  
    echo "Received signal, exiting..."  
    # 在这里执行任何必要的清理工作  
    exit 0  
}  
  
# 捕获SIGTERM信号  
trap handle_signal SIGTERM  


while [ 1 -eq 1 ]
do
    if [ -z "$Proxy" ]; then  
        `/bin/bash namesiloddns-dk.sh`
        sleep ${looptime:-10}m
    else
        cp /etc/proxychains/proxychains.conf /etc/proxysock5.conf
        sed -i "s/^socks4 	127.0.0.1 9050/socks5 	${Proxy}/" "/etc/proxysock5.conf"  
        `proxychains -q -f /etc/proxysock5.conf /bin/bash namesiloddns-dk.sh`
        sleep ${looptime:-10}m
    fi  
    
done