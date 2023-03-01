#!/bin/sh

#需要的环境变量:
#NamesiloApiKey 域名商namesilo api的key
#Email          用户邮箱
#DomainName     SSL证书域名
#SynoHostname   群晖地址
#SynoUsername   群晖用户名
#SynoPassword   群晖密码
#LoopTime       循环天数
Stime="$(date +\%Y-\%m-\%d-\%H:\%M) --"
ConfPath="/acmessl/certs/${DomainName}_ecc/${DomainName}.conf"
while [ 1 -eq 1 ]; do

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

#初始化并使用强制更新证书
funNew_Cert() {
  echo "${Stime}:-配置文件不存在,初始化开始" >> /acmessl/run.log 2>&1
  export Namesilo_Key="${NamesiloApiKey}"
  sh /acmessl/acme.sh --config-home /acmessl/data --register-account -m "${Email}" &&
    sh /acmessl/acme.sh --config-home /acmessl/data --issue --dns dns_namesilo --dnssleep 900 -d ${DomainName} -d ${SubDomainName} | grep 'Cert success' && funUpdate_Cert
}

#刷新证书
funRenew_Cert() {
  InfoReturn=$(sh /acmessl/acme.sh --config-home /acmessl/data --renew-all)
  { 
  echo "-----------刷新证书------------" 
  "${Stime}:↓" 
  "$InfoReturn" 
  "-------------------------------" 
  } >> /acmessl/run.log 2>&1
  if grep -q "Skipped ${DomainName}_ecc" "$InfoReturn"; then
    echo "${Stime}:-证书到期时间大于30天" >> /acmessl/run.log 2>&1
  else 
    echo "${Stime}:-证书刷新" >> /acmessl/run.log 2>&1
  fi
}

#将证书更新至群晖
funUpdate_Cert() {
  echo "${Stime}:-证书已更新,替换开始"
  export SYNO_Hostname="${SynoHostname}"
  export SYNO_Username="${SynoUsername}"
  export SYNO_Password="${SynoPassword}"
  export SYNO_Certificate="${DomainName}"
  sh /acmessl/acme.sh --config-home /acmessl/data --deploy -d "${DomainName}" --deploy-hook synology_dsm
}
