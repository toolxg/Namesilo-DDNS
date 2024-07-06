# NamesiloDDNS

## 感谢 [pztop/namesilo_ddns](https://github.com/pztop/namesilo_ddns)

## 前置
#### 在域名管理内新增需要使用的A记录 (已有跳过)
#### 获取APIkey
APIkey获取地址: **https://www.namesilo.com/account/api-manager**

## Docker容器使用方法
### 下载容器镜像
[镜像下载](https://github.com/toolxg/Namesilo-DDNS-SSL/releases)
>镜像构建文件在DDNS/Dockerimages内,可以自行构建镜像

### 导入容器镜像
`docker load -i namesiloddns-vx.tar`

### 创建容器所需要求
```
# 根据需求挂载日志文件ddnslog.log(可选)与时区文件localtime (可选)
# 挂载日志文件需先在宿主机内创建日志文件

# 环境变量(注意大小写):
DOMAIN=""   #域名: (必填)
HOST=""     #主机名: (必填)
APIKEY=""   #APIkey: (必填)
PROXY=""    #socks5代理: (可选)
LOOPTIME="" #脚本循环间隔: 默认为10分钟 (可选)
UTO=""      #公网IP获取接口超时事件(秒): 默认为5秒 (可选)
```
### 创建容器示例
```
@: docker run --name ddns -t \
    -e DOMAIN="test.com" \
    -e HOST="ddns" \
    -e APIKEY="ApiKey" \
    -e PROXY="192.168.1.1 1080" \
    -v /var/log/ddnslog.log:/ddns/ddnslog.log \
    -v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
    -d namesiloddns:v0.2
```
