#!/bin/bash

### 用户数据
# 域名
env_domain=$DOMAIN

# 前缀主机名
env_host=$HOST

# API key
env_api_key=$APIKEY

# 代理模式
proxy_model=$PROXY_MODEL

# 接口超时时间(秒)
# UTO=url time out
# url_t_o=url time out
url_t_o=${UTO:-5}

### 日志配置
# 日志级别: DEBUG=0, INFO=1, WARN=2, ERROR=3
log_level=${LOG_LEVEL:-1}
log_file=$LOG_FILE
log_module="DDNS-Docker"

### 脚本定义
## 获取运行目录
# dirname $0，取得当前执⾏的脚本⽂件的⽗⽬录
# cd `dirname $0`，进⼊这个⽬录(切换当前⼯作⽬录)
# pwd,显⽰当前⼯作⽬录(cd执⾏后的)
# run_path=run path
run_path="$(cd `dirname $0`; pwd)/"

## 判断用户数据是否为空
if [[ -z $env_domain ]] || [[ -z $env_host ]] || [[ -z $env_api_key ]]; then
    log "ERROR" "环境变量存在未填写项，注意检查配置 >DOMAIN< >HOST< >APIKEY< 为必填项"
    exit 1
fi

### 通用日志
log() {
    # 用法: log <LEVEL> <MESSAGE>
    # LEVEL: DEBUG, INFO, WARN, ERROR
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 定义日志级别数值
    declare -A level_values=( ["DEBUG"]=0 ["INFO"]=1 ["WARN"]=2 ["ERROR"]=3 )
    local current_level=${level_values[$level]:-1}
    
    # 检查是否达到日志级别阈值
    if (( current_level < log_level )); then
        return
    fi
    
    # 格式化日志消息
    local log_message="[${timestamp}] [${level}] [${log_module}] ${message}"
    
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
    
    # 如果设置了LOG_FILE则输出到日志文件
    if [ -n "$log_file" ]; then
        echo "$log_message" >> "$log_file"
    fi
}

## 获取公网IP的接口
get_IP(){
    local get_ipurl=()

    # 亚马逊
    get_ipurl[1]="https://checkip.amazonaws.com"

    # 开源外网IP api
    get_ipurl[2]="https://api.ipify.org"
    #
    get_ipurl[3]="https://ifconfig.me/ip"
    #
    get_ipurl[4]="https://api.my-ip.io/ip"
    
    ## 获取公网iP
    # ni_ip=New internet IP
    # gi_ip_c=Get internet IP code
    local i gi_ip_c
    ni_ip=""
    for i in "${get_ipurl[@]}"; do
        # --connect-timeout 设置连接超时时间以免过长时间的等待
        if ni_ip=$(curl --connect-timeout "$url_t_o" -s -f "$i"); then
            log "INFO" "获取公网IP成功, 公网IP为 $ni_ip"
            return 0
        fi
    done
    log "ERROR" "获取公网IP接口错误,检查网络环境"
    exit 1
}


### 判断地址是否可达(用于确认是否需要使用代理)
is_url_reachable() {
    local url="$1"
    curl --head --output /dev/null --silent \
    --connect-timeout 10 --max-time 15 --retry 0 --fail "$url" 2>/dev/null
}

### 判断是否需要代理,并获取namesilo DNS列表
get_DNSList(){
    # api_data 获取api数据
    # host_arr 分割env_host的输入数据
    # records 存放解析到的DNS列表数据
    local proxy_code=$1
    local api_data=""
    local host_arr=(${env_host//,/ })
    local api_url_tmp="https://www.namesilo.com/api/dnsListRecords?version=1&type=json&key=$env_api_key&domain=$env_domain"
    log "DEBUG" "获取DNS列表, 构造URL:"
    log "DEBUG" "$api_url_tmp"
    if [[ "$proxy_code" -eq 0 ]]; then
        log "DEBUG" "直连获取DNS列表"
        api_data=$(curl -s "$api_url_tmp")
    else
        log "DEBUG" "代理获取DNS列表"
        api_data=$(curl -s -x "${PROXY}" "$api_url_tmp")
    fi
    log "DEBUG" "DNS列表获取, 返回的API数据为:"
    log "DEBUG" "${api_data}"

    ## 判断是否获取到namesilo DNS列表,并提取DNS A记录IP
    if jq -e '.reply.code == 300' <<< "$api_data" > /dev/null 2>&1; then
        local item record_id host value ttl
        for item in "${host_arr[@]}"; do
            log "DEBUG" "当前进行主机 ${item}, 更新"
            jq -r --arg t "$item" '
            .reply.resource_record[]? 
            | select(.type == "A" and .host == $t) 
            | "\(.record_id) \(.host) \(.value) \(.ttl)"
            ' <<< "$api_data" | while read -r record_id host nowip ttl; do
                if [[ "$ni_ip" != "$nowip" ]]; then
                    log "DEBUG" "put_DNS构造-代理模式:$proxy_code, record_id:$record_id, 前缀域名:$host, 新IP:$ni_ip, 旧IP:$nowip, TTL:$ttl"
                    put_DNS "$proxy_code" "$record_id" "$host" "$ni_ip" "$nowip" "$ttl"
                else
                    log "INFO" "主机A记录 ${host}, IP相同无需更新"
                fi
            done
        done
    else
        local error_code=$(jq -r '.reply.code // "未知错误码"' <<< "$api_data")
        log "ERROR" "API错误, 错误代码为: ${error_code}, DNS列表获取失败"
        exit 1
    fi
        
}

### 判断本次获取与上次获取IP是否相同
## put_DNS 代理使用模式 recordID host前缀域名 新IP 旧IP ttl
put_DNS(){
    local proxy_code=$1
    local record_id=$2
    local host=$3
    local new_ip=$4
    local old_ip=$5
    local ttl=$6
    local api_data=""

    ### 更新DNS记录
    ## 判断是否需要代理,并更新DNS记录
    local api_url_tmp="https://www.namesilo.com/api/dnsUpdateRecord?version=1&type=json&key=$env_api_key&domain=$env_domain&rrid=$record_id&rrhost=$host&rrvalue=$new_ip&rrttl=$ttl"
    log "DEBUG" "更新DNS, 构造URL:"
    log "DEBUG" "$api_url_tmp"
    if [[ "$proxy_code" -eq 0 ]]; then
        log "DEBUG" "直连更新DNS"
        api_data=$(curl -s "$api_url_tmp")
    else
        log "DEBUG" "代理更新DNS"
        api_data=$(curl -s -x "${PROXY}" "$api_url_tmp")
    fi
    log "DEBUG" "DNS更新, 返回的API数据为:"
    log "DEBUG" "${api_data}"
    if jq -e '.reply.code == 300' <<< "$api_data" > /dev/null 2>&1; then
        log "INFO" "主机A记录 ${host}, IP地址由 >${old_ip}< 更改为 >$new_ip<"
    else
        local error_code=$(jq -r '.reply.code // "未知错误码"' <<< "$api_data")
        log "ERROR" "API错误, 错误代码为: ${error_code}, DNS更新失败"
        exit 1
    fi
}


### 启动入口
##获取公网IP
get_IP

## 测试直连是否成功 成功使用直连提交不成功使用代理提交
case $proxy_model in
    0)
        if is_url_reachable "https://www.namesilo.com/api/?version=1&type=json"; then
            log "INFO" "直连通信成功,使用直连连接API"
            get_DNSList "0"
        else
            log "INFO" "直连通信失败,使用代理连接API"
            get_DNSList "1"
        fi
        ;;
    1)
        get_DNSList "0"
        ;;
    2)
        get_DNSList "1"
        ;;
esac

exit 0