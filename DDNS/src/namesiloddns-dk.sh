#!/bin/bash

### 用户数据
# 域名
DOMAIN=$DOMAIN
# 前缀主机名
HOST=$HOST
# API key
APIKEY=$APIKEY
# 接口超时时间(秒)
# UTO=url time out
UTO=${UTO:-5}

### 日志配置
# 日志级别: DEBUG=0, INFO=1, WARN=2, ERROR=3
LOG_LEVEL=${LOG_LEVEL:-1}
LOG_FILE=""
LOG_MODULE="DDNS-Docker"

### 通用日志函数
# 用法: log <LEVEL> <MESSAGE>
# LEVEL: DEBUG, INFO, WARN, ERROR
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 定义日志级别数值
    declare -A level_values=( ["DEBUG"]=0 ["INFO"]=1 ["WARN"]=2 ["ERROR"]=3 )
    local current_level=${level_values[$level]:-1}
    
    # 检查是否达到日志级别阈值
    if (( current_level < LOG_LEVEL )); then
        return
    fi
    
    # 格式化日志消息
    local log_message="[${timestamp}] [${level}] [${LOG_MODULE}] ${message}"
    
    # 输出到控制台（Docker环境主要使用stdout/stderr）
    case $level in
        ERROR)
            echo "$log_message" >&2
            ;;
        WARN)
            echo "$log_message" >&2
            ;;
        *)
            echo "$log_message"
            ;;
    esac
    
    # 输出到日志文件（如果设置了LOG_FILE）
    if [ -n "$LOG_FILE" ]; then
        echo "$log_message" >> "$LOG_FILE"
    fi
}

### 脚本定义
## 获取运行目录
# dirname $0，取得当前执⾏的脚本⽂件的⽗⽬录
# cd `dirname $0`，进⼊这个⽬录(切换当前⼯作⽬录)
# pwd,显⽰当前⼯作⽬录(cd执⾏后的)
# Rpath=run path
Rpath="$(cd `dirname $0`; pwd)/"

## 判断用户数据是否为空
if [[ -z $DOMAIN ]] || [[ -z $HOST ]] || [[ -z $APIKEY ]]; then
    log "ERROR" "环境变量存在未填写项，注意检查配置 >DOMAIN< >HOST< >APIKEY< 为必填项"
    exit 1
fi

### 判断公网IP是否更新
## 获取公网IP的接口
# 亚马逊
IPURL[1]="https://checkip.amazonaws.com"
# 开源外网IP api
IPURL[2]="https://api.ipify.org"
#
IPURL[3]="https://ifconfig.me/ip"
#
IPURL[4]="https://api.my-ip.io/ip"

## 获取公网iP 
i=0
while (($i < 4))
do
    ((i++))
    # 使用curl -w 获取返回状态码，使用-o 输出至文件使判断更简单,-s 静默输出。
    # 因curl使用-w时会与返回的网页数据组合但无明显分割所以将网页数据导出至文件。
    # --connect-timeout 设置连接超时时间以免过长时间的等待
    # GIIPS=Get internet IP status
    # NIIPS=New internet IP status
    GIIPS=`curl --connect-timeout $UTO -o ${Rpath}nowip -s -w %{http_code} ${IPURL[$i]}`
    # 判断返回的状态码为200则跳出循环，否则继续循环。
    if (($GIIPS == "200")); then 
        NIIPS=`cat ${Rpath}nowip`
        break
    fi
    # 在循环最后一次后仍然无法获取则退出脚本并输出错误。
    if (($i == 4)); then
        log "ERROR" "获取公网IP接口错误,检查网络环境"
        exit 1
    fi
done

## 判断是否需要socks5,并获取namesilo DNS列表
if [ -z "$PROXY" ]; then
    curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > ${Rpath}${DOMAIN}.xml
else
    proxychains -q -f /etc/proxysock5.conf curl -s "https://www.namesilo.com/api/dnsListRecords?version=1&type=xml&key=$APIKEY&domain=$DOMAIN" > ${Rpath}${DOMAIN}.xml
fi

## 判断是否获取到namesilo DNS列表,并提取DNS A记录IP
if [ -s "${Rpath}${DOMAIN}.xml" ]; then  
    ExistingIP=`xmllint --xpath "//namesilo/reply/resource_record/value[../host/text() = '${HOST}' ]"  ${Rpath}${DOMAIN}.xml | grep -oP '(?<=<value>).*?(?=</value>)'`
else  
    log "ERROR" "namesilo Api接口错误,未获取到DNS列表数据"
    exit 1
fi


## 判断本次获取与上次获取IP是否相同
if [ "$NIIPS" = "$ExistingIP" ]; then
    log "INFO" "公网IP未改变"
    echo -e "" > ${Rpath}${DOMAIN}.xml
    exit 0
else
    log "INFO" "公网IP由>$ExistingIP<更改为>$NIIPS<"
fi

### 更新DNS记录
## 提取A记录resource id
ResourceID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '${HOST}' ]"  ${Rpath}${DOMAIN}.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`

## 判断是否需要socks5,并更新DNS记录
if [ -z "$PROXY" ]; then
    curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$ResourceID&rrhost=$HOST&rrvalue=$NIIPS&rrttl=3600" > ${Rpath}${DOMAIN}-ret.xml
else
    proxychains -q -f /etc/proxysock5.conf curl -s "https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=xml&key=$APIKEY&domain=$DOMAIN&rrid=$ResourceID&rrhost=$HOST&rrvalue=$NIIPS&rrttl=3600" > ${Rpath}${DOMAIN}-ret.xml
fi

## 判断是否提交成功
# Api状态解析 https://www.namesilo.com/api-reference
# submitS=submit status
submitS=`xmllint --xpath "//namesilo/reply/code/text()"  ${Rpath}${DOMAIN}-ret.xml`
if [ -z "$submitS" ]; then
    log "ERROR" "Api更新错误，无法获取返回状态码。请检查 ${Rpath}${DOMAIN}-ret.xml 文件内容"
    log "DEBUG" "API返回内容: $(cat ${Rpath}${DOMAIN}-ret.xml 2>/dev/null | head -c 500)"
    log "WARN" "公网IP未更改"
    echo -e "" > ${Rpath}${DOMAIN}.xml
elif [ "$submitS" = "300" ]; then
    log "INFO" "Api更新成功"
    echo -e "" > ${Rpath}${DOMAIN}.xml
else
    log "ERROR" "Api更新错误,返回状态码为[$submitS]"
    log "DEBUG" "API返回内容: $(cat ${Rpath}${DOMAIN}-ret.xml 2>/dev/null | head -c 500)"
    log "WARN" "公网IP未更改"
    echo -e "" > ${Rpath}${DOMAIN}.xml
fi

exit 0