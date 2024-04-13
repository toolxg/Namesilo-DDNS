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
    `/bin/bash namesiloddns-dk.sh`
    sleep ${looptime:-10}m
done