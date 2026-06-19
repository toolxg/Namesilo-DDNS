# NamesiloDDNS

## 感谢 [pztop/namesilo_ddns](https://github.com/pztop/namesilo_ddns)

## 前置准备
### 1. 在域名管理内新增需要使用的A记录 (已有跳过)
### 2. 获取APIkey
APIkey获取地址: **https://www.namesilo.com/account/api-manager**

> ⚠️ **注意**: APIkey具有域名管理权限，请妥善保管，不要泄露

## Docker容器使用方法

### 下载容器镜像
[镜像下载](https://github.com/toolxg/Namesilo-DDNS-SSL/releases)
> 镜像构建文件在DDNS/Dockerimages内,可以自行构建镜像

### 导入容器镜像
```bash
docker load -i namesiloddns-vx.tar
```

### 创建容器

#### 容器环境变量说明

##### 必填参数
```bash
DOMAIN=""      # 域名，例如: example.com
HOST=""        # 主机名（A记录前缀），例如: ddns（完整域名为 ddns.example.com）
APIKEY=""      # Namesilo API Key
```

##### 可选参数
```bash
TZ=""          # 时区设置，默认: Asia/Shanghai
PROXY=""       # 代理网关地址，格式: "IP 端口"，例如: "socks5/http 192.168.1.1 1080"
LOOPTIME=""    # DDNS检查间隔时间（分钟），默认: 15分钟
UTO=""         # 公网IP获取接口超时时间（秒），默认: 5秒
LOG_LEVEL=""   # 日志级别，可选值: 0(DEBUG), 1(INFO), 2(WARN), 3(ERROR)，默认: 1
```

##### 参数详细说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| DOMAIN | 必填 | - | 您的域名，如 example.com |
| HOST | 必填 | - | A记录的主机名前缀，如 ddns（完整域名：ddns.example.com） |
| APIKEY | 必填 | - | Namesilo账户的API密钥 |
| TZ | 可选 | Asia/Shanghai | 容器时区，影响日志时间戳 [时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| PROXY | 可选 | - | 代理网关服务器地址，格式为 "协议 IP 端口"，用于网络环境受限场景 |
| LOOPTIME | 可选 | 15 | DDNSapi检查间隔时间，单位：分钟。建议不小于5分钟，避免频繁API调用 |
| UTO | 可选 | 5 | 获取公网IP接口的连接超时时间，单位：秒。网络较差时可适当增加 |
| LOG_LEVEL | 可选 | 1 | 日志输出级别：0=全部日志(DEBUG), 1=信息及以上(INFO), 2=警告及以上(WARN), 3=仅错误(ERROR) |

> 💡 **提示**: 获取镜像定义的环境变量可使用命令：
> ```bash
> docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' [镜像名称:版本]
> ```

#### 日志说明

容器使用标准化的日志格式输出：
```
[2024-01-01 12:00:00] [INFO] [DDNS-Docker] 公网IP未改变
[2024-01-01 12:10:00] [INFO] [DDNS-Docker] 公网IP由>192.168.1.1<更改为>192.168.1.2<
[2024-01-01 12:10:01] [INFO] [DDNS-Docker] Api更新成功
```

日志级别说明：
- **DEBUG (0)**: 调试信息，包含API返回详情等
- **INFO (1)**: 正常操作信息（默认级别）
- **WARN (2)**: 警告信息
- **ERROR (3)**: 错误信息

查看容器日志：
```bash
# 查看实时日志
docker logs -f ddns

# 查看最近100行日志
docker logs --tail 100 ddns
```

#### 创建容器示例

##### 基础示例（无代理）
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e TZ="Asia/Shanghai" \
    -d namesiloddns:v0.2
```

##### 使用SOCKS5代理
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e TZ="Asia/Shanghai" \
    -e PROXY="192.168.1.1 1080" \
    -d namesiloddns:v0.2
```

##### 自定义检查间隔和超时时间
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e TZ="Asia/Shanghai" \
    -e LOOPTIME="5" \
    -e UTO="10" \
    -e LOG_LEVEL="0" \
    -d namesiloddns:v0.2
```

##### 挂载日志文件到宿主机（可选）
> ⚠️ **注意**: 挂载日志文件需先在宿主机内创建日志文件并设置适当权限

```bash
# 创建日志文件
touch /var/log/ddns.log
chmod 666 /var/log/ddns.log

# 运行容器并挂载日志
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e TZ="Asia/Shanghai" \
    -v /var/log/ddns.log:/ddns/ddns.log \
    -d namesiloddns:v0.2
```

## 注意事项

### 1. API调用频率限制
- Namesilo API有调用频率限制，建议 `LOOPTIME` 设置为 **10分钟或以上**
- 过短的检查间隔可能导致API被临时封禁

### 2. 网络环境
- 确保容器能够访问外网以获取公网IP
- 如果在中国大陆，可能需要配置 `PROXY` 参数使用代理
- 支持的公网IP获取接口会自动切换（Amazon、ipify、ifconfig.me、my-ip.io）

### 3. DNS记录要求
- **必须提前在Namesilo控制台创建对应的A记录**
- HOST参数填写的是A记录的前缀，不是完整域名
- 例如：要为 `ddns.example.com` 更新DNS，则 `DOMAIN=example.com`，`HOST=ddns`

### 4. 时区设置
- 务必正确设置 `TZ` 参数，否则日志时间可能不准确
- 常用时区参考：
  - 中国标准时间: `Asia/Shanghai`
  - 日本标准时间: `Asia/Tokyo`
  - 美国东部时间: `America/New_York`
  - UTC时间: `UTC`

### 5. 日志管理
- 默认日志输出到容器stdout/stderr，可通过 `docker logs` 查看
- 如需持久化日志，可挂载日志文件到宿主机
- 建议定期清理或轮转日志文件，避免占用过多磁盘空间

### 6. 安全建议
- **不要将APIKey硬编码在脚本中**，始终通过环境变量传递
- 不要在公开场合分享包含APIKey的日志或配置文件
- 定期轮换APIKey以提高安全性
- 考虑使用Docker secrets或外部密钥管理服务存储敏感信息

### 7. 故障排查

#### 问题1: 容器启动后立即退出
```bash
# 查看容器日志
docker logs ddns

# 常见原因：
# - 缺少必填环境变量（DOMAIN、HOST、APIKEY）
# - APIKey无效或权限不足
# - 域名不存在或未创建A记录
```

#### 问题2: 无法获取公网IP
```bash
# 检查网络连接
docker exec ddns ping -c 3 checkip.amazonaws.com

# 尝试增加超时时间
-e UTO="15"

# 如果使用代理，检查代理配置是否正确
-e PROXY="192.168.1.1 1080"
```

#### 问题3: API更新失败
```bash
# 查看详细日志
docker logs ddns | grep ERROR

# 检查APIKey是否有效
# 检查域名和主机名是否正确
# 确认A记录已存在
```

#### 问题4: 日志显示状态码为空
- 可能是XML解析失败
- 检查 `${Rpath}${DOMAIN}-ret.xml` 文件内容
- 设置 `LOG_LEVEL=0` 查看API返回的原始内容

### 8. 容器管理

```bash
# 停止容器
docker stop ddns

# 启动容器
docker start ddns

# 重启容器
docker restart ddns

# 删除容器
docker rm -f ddns

# 查看容器状态
docker ps -a | grep ddns

# 进入容器内部（调试用）
docker exec -it ddns /bin/bash
```