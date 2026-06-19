#!/bin/bash

handle_signal() {  
    echo "Received signal, exiting..."  
    exit 0  
}  
  
# 捕获SIGTERM信号  
trap handle_signal SIGTERM  

# 循环执行
while [ 1 -eq 1 ]
do
    /bin/bash namesiloddns-dk.sh
    sleep ${LOOPTIME:-15}m
done