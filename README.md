# NamesiloDDNS

## 感谢 [pztop/namesilo_ddns](https://github.com/pztop/namesilo_ddns)

### 前置
#### 在域名管理内新增需要使用的A记录 (已有跳过)
#### 获取APIkey
APIkey获取地址: **https://www.namesilo.com/account/api-manager**

#### 需要的软件
```
# 大部分发行版中无需安装 默认已安装
curl
grep
libxml
bash
cron # 此服务需开机运行
```

---

### 本地环境使用方法
#### 创建文件夹并下载Shell脚本
```
mkdir namesiloddns
cd namesiloddns
wget 
```

#### 修改Shell脚本内以下参数
>以域名A记录 ddns.test.com 为例子

```
# 进入shell脚本
vi namesiloddns.sh

...
DOMAIN="" #必填 例:test.com

HOST=""   #必填 例:ddns

APIKEY="" #必填 上方获取的ApiKey

looptime="*/10 * * * *" #可选 cron循环时间默认>10分钟运行一次<(请参照 cron 规则填写)
...

#保存并退出
:wq
```

#### 添加权限与运行
```
chmod +x namesiloddns.sh
/bin/bash namesiloddns.sh 或 ./namesiloddns.sh
```
#### 完成
**运行脚本后将会在登录用户下的cron文件内创建循环规则无需设置cron规则
日志文件为Shell脚本根目录下的ddnslog.log**

---

### Docker容器使用方法
#### 下载容器(腾讯云仓库)
```
docker pull ccr.ccs.tencentyun.com/gtool/namesiloddns
```
>Docker构建文件在Dockerimages内,可以自行构建镜像,镜像大小在8M左右


#### 创建容器
```
# 根据需求挂载日志文件ddnslog.log与时区文件localtime (非关键项)
# 挂载日志文件需先在宿主机内创建日志文件否则Docker将自动创建文件夹非文件

# 环境变量(注意大小写):
# 域名: 必填
DOMAIN=""
# 主机名: 必填
HOST=""
# APIkey: 必填
APIKEY=""
# 脚本循环间隔： 可选
looptime="默认为10分钟"
```
##### 示例代码:
```
docker run --name ddns -t \
    -e DOMAIN="test.com" \
    -e HOST="ddns" \
    -e APIKEY="ApiKey" \
    -v /var/log/ddnslog.log:/ddns/ddnslog.log \
    -v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
    -d ccr.ccs.tencentyun.com/gtool/namesiloddns:latest
```
