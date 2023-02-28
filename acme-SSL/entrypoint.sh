#!/bin/sh

while [ 1 -eq 1 ]; do
  if [ ! -d "/acmessl/certs" ]; then
    mkdir /acmessl/certs
    funNew_Cert
  fi
  sleep "${looptime:-15}"d
done

funNew_Cert() {
  echo "证书不存在,申请开始"
  export Namesilo_Key="${NamesiloApiKey}"
  sh /acmessl/acme.sh --issue --dns dns_namesilo --dnssleep 900 -d ${DomainName} -d ${SubDomainName} | grep 'su' && funUpdate_Cert
}

funUpdate_Cert(){
echo "证书已更新,替换开始"
export SYNO_Create=1
export SYNO_Certificate="${DomainName}"
/usr/local/acme.sh/acme.sh --config-home /usr/local/acme.sh/data --deploy -d example.com --deploy-hook synology_dsm
}