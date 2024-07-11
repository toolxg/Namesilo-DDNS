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

### 脚本定义
## 定义时间格式(使用于日志)
# Stime=systeml time
Stime="$(date +\%Y-\%m-\%d-\%H:\%M) --"

## 获取运行目录
# dirname $0，取得当前执⾏的脚本⽂件的⽗⽬录
# cd `dirname $0`，进⼊这个⽬录(切换当前⼯作⽬录)
# pwd,显⽰当前⼯作⽬录(cd执⾏后的)
# Rpath=run path
Rpath="$(cd `dirname $0`; pwd)/"

## 判断用户数据是否为空
if [[ -z $DOMAIN ]] || [[ -z $HOST ]] || [[ -z $APIKEY ]]; then
    echo $Stime "环境变量存在未填写项，注意检查配置 >DOMAIN< >HOST< >APIKEY< 为必填项" >> ${Rpath}ddnslog.log
    
    exit 0
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
        echo $Stime "获取公网IP接口错误,检查网络环境" >> ${Rpath}ddnslog.log
        exit 0
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
    ExistingIP=`xmllint --xpath "//namesilo/reply/resource_record/value[../host/text() = '${HOST}.${DOMAIN}' ]"  ${Rpath}${DOMAIN}.xml | grep -oP '(?<=<value>).*?(?=</value>)'`
else  
    echo $Stime "namesilo Api接口错误,未获取到DNS列表数据" >> ${Rpath}ddnslog.log
    exit 0
fi


## 判断本次获取与上次获取IP是否相同
if [ "$NIIPS" = "$ExistingIP" ]; then
    echo $Stime "公网IP未改变" >> ${Rpath}ddnslog.log
    echo -e "" > ${Rpath}${DOMAIN}.xml
    exit 0
else
    echo $Stime "公网IP由>$ExistingIP<更改为>$NIIPS<"  >> ${Rpath}ddnslog.log
fi

### 更新DNS记录
## 提取A记录resource id
ResourceID=`xmllint --xpath "//namesilo/reply/resource_record/record_id[../host/text() = '${HOST}.${DOMAIN}' ]"  ${Rpath}${DOMAIN}.xml | grep -oP '(?<=<record_id>).*?(?=</record_id>)'`

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
if [ "$submitS" = "300" ]; then
    echo $Stime "Api更新成功" >> ${Rpath}ddnslog.log
    echo -e "" > ${Rpath}${DOMAIN}.xml
    else
    echo $Stime "Api更新错误,返回状态码为$submitS" >> ${Rpath}ddnslog.log
    echo $Stime "公网IP未更改" >> ${Rpath}ddnslog.log
    echo -e "" > ${Rpath}${DOMAIN}.xml
fi

exit 0