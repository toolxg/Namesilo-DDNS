#!/bin/sh

#需要的环境变量:
#NamesiloApiKey 域名商namesilo api的key
#Email          用户邮箱用于申请证书
#DomainName     SSL证书域名
#可选
#SubDomainName  子域名 默认为泛域名*
#LoopTime       循环天数

#-----acme脚本固定环境变量设置-----
#export SYNO_Username="adminUser" - 用户名
#export SYNO_Password="adminPassword" - 密码
#export SYNO_Scheme="http" 
#export SYNO_Hostname="url"
#export SYNO_Port="5000"
#可选
#export SYNO_USE_TEMP_ADMIN=1  - 自动创建临时管理员用户(用于直接运行在群晖中)
#export SYNO_Certificate="" - 通过描述替换特定证书
#export SYNO_Create=1 - 允许创建证书（如果证书不存在）
#export SYNO_Device_Name="CertRenewal"  - 如果启用了 2FA-OTP，则需要
#export SYNO_Device_ID="" - 跳过2FA-OTP验证所需
#---------------------------

handle_signal() {  
    echo "Received signal, exiting..."  2>&1
    # 在这里执行任何必要的清理工作  
    exit 0  
}  
  
# 捕获SIGTERM信号  
trap handle_signal SIGTERM  

Stime="$(date +\%Y-\%m-\%d-\%H:\%M) --"
ConfPath="/acmessl/certs/${DomainName}_ecc/${DomainName}.conf"
while [ 1 -eq 1 ]; do
  #检查必要的环境变量警告并退出容器
  check_Export

  #判断证书文件夹内是否存在配置文件
  #不存在:使用函数 funNew_Cert 新建证书
  #存在:使用函数 funRenew_Cert 刷新证书
  if [ ! -f "$ConfPath" ]; then
    funNew_Cert
  else
    funRenew_Cert
  fi

  sleep "${LoopTime:-15}"d
done

check_Export (){

if [ -z "$SYNO_Username" ]; then  
    echo "$(Stime):export $SYNO_Username invalid" 2>&1
    exit 0  
fi
if [ -z "$SYNO_Password" ]; then
    echo "$(Stime):export $SYNO_Password invalid"  2>&1
    exit 0 
fi
if [ -z "$SYNO_Password" ]; then
    echo "$(Stime):export $SYNO_Password invalid"  2>&1
    exit 0 
fi
if [ -z "$SYNO_Scheme" ]; then
    export SYNO_Scheme="http"
fi
if [ -z "$SYNO_Hostname" ]; then
    echo "$(Stime):export $SYNO_Hostname invalid"  2>&1
    exit 0 
fi
if [ -z "$SYNO_Port" ]; then
    echo "$(Stime):export $SYNO_Port invalid"  2>&1
    exit 0 
fi
if [ -z "$NamesiloApiKey" ]; then
    echo "$(Stime):export $NamesiloApiKey invalid"  2>&1
    exit 0 
fi
if [ -z "$Email" ]; then
    echo "$(Stime):export $Email invalid"  2>&1
    exit 0 
fi
if [ -z "$DomainName" ]; then
    echo "$(Stime):export $DomainName invalid"  2>&1
    exit 0 
fi
}


#初始化并使用强制更新证书
# acme.sh --deploy --deploy-hook synology_dsm -d example.com
funNew_Cert() {
  echo "${Stime}:-配置文件不存在,初始化开始" >> /acmessl/run.log 2>&1
  export Namesilo_Key="${NamesiloApiKey}"
  sh /acmessl/acme.sh --config-home /acmessl/data --register-account -m "${Email}" && sh /acmessl/acme.sh --deploy --deploy-hook synology_dsm --config-home /acmessl/data --dns dns_namesilo --dnssleep 900 -d ${DomainName} -d ${SubDomainName:-"*"} | grep 'Cert success'
}

#刷新证书
funRenew_Cert() {
  InfoReturn=$(sh /acmessl/acme.sh --deploy --deploy-hook synology_dsm --config-home /acmessl/data --renew-all)
  { 
  echo "-----------刷新证书------------" 
  "${Stime}:↓" 
  "$InfoReturn" 
  "-------------------------------" 
  } >> /acmessl/run.log 2>&1
  if grep -q "Skipped ${DomainName}_ecc" "$InfoReturn"; then
    echo "${Stime}:-证书到期时间大于30天" >> /acmessl/run.log 2>&1
  else 
    echo "${Stime}:-已将证书重新刷新" >> /acmessl/run.log 2>&1
  fi
}
