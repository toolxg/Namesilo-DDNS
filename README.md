# NamesiloDDNS

## 前置准备
### 1. 在域名管理内新增需要使用的A记录 (已有跳过)
### 2. 获取APIkey
APIkey获取地址: **https://www.namesilo.com/account/api-manager**

> **注意**: APIkey具有域名管理权限,请妥善保管,不要泄露,如在DMZ区域请保证系统安全

## Docker容器使用方法

### 下载容器镜像
[镜像下载](https://github.com/toolxg/Namesilo-DDNS-SSL/releases)
> 镜像构建文件在DDNS/Dockerimages内,可以自行构建镜像

### 导入容器镜像
```bash
docker load -i namesiloddns-vx.x.tar
```

### 创建容器

#### 容器环境变量说明

##### 必填参数
```bash
DOMAIN=""      # 域名,例如: example.com
HOST=""        # 主机名(A记录前缀),例如: ddns(完整域名为 ddns.example.com),支持多个主机名用逗号分隔
APIKEY=""      # Namesilo API Key
```

##### 可选参数
```bash
TZ=""          # 时区设置,默认: Asia/Shanghai
PROXY=""       # 代理地址,格式: "协议://IP:端口",例如: "socks5://192.168.1.1:1080" 或 "http://192.168.1.1:8080"
LOOPTIME=""    # DDNS检查间隔时间(分钟),默认: 15分钟
UTO=""         # 公网IP获取接口超时时间(秒),默认: 5秒
LOG_LEVEL=""   # 日志级别,可选值: 0(DEBUG), 1(INFO), 2(WARN), 3(ERROR),默认: 1
LOG_FILE=""    # 日志文件路径
PROXY_MODEL=0  # 代理模式,可选值: 0(自动), 1(直连),2(代理),默认: 0
```

##### 参数详细说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| DOMAIN | 必填 | - | 您的域名,如 example.com |
| HOST | 必填 | - | A记录的主机名前缀,如 ddns(完整域名:ddns.example.com)。**支持多个主机名,用逗号分隔**,例如: `ddns,www,home` |
| APIKEY | 必填 | - | Namesilo账户的API密钥 |
| TZ | 可选 | Asia/Shanghai | 容器时区,影响日志时间戳 [时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) |
| PROXY | 可选 | - | 代理服务器地址,格式为 "协议://IP:端口",用于网络环境受限场景。支持的协议: socks4//, socks4a//(使用代理服务器DNS), socks5//, socks5h//(使用代理服务器DNS), http//, https// |
| LOOPTIME | 可选 | 15 | DDNS检查间隔时间,单位:分钟。建议不小于5分钟,避免频繁API调用 |
| UTO | 可选 | 5 | 获取公网IP接口的连接超时时间,单位:秒。网络较差时可适当增加 |
| LOG_LEVEL | 可选 | 1 | 日志输出级别:0=全部日志(DEBUG), 1=信息及以上(INFO), 2=警告及以上(WARN), 3=仅错误(ERROR) |
| LOG_FILE | 可选 | - | 日志文件路径,默认不启用 |
| PROXY_MODEL | 可选 | 0 | 代理模式: 0=智能模式(先测试直连,失败则使用代理), 1=强制直连, 2=强制代理 |

> 💡 **提示**: 获取镜像定义的环境变量可使用命令:
> ```bash
> docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' [镜像名称:版本]
> ```

#### 日志说明

容器使用标准化的日志格式输出:
```
[2024-01-01 12:00:00] [INFO] [DDNS-Docker] 公网IP未改变
[2024-01-01 12:10:00] [INFO] [DDNS-Docker] 主机A记录 ddns, IP地址由 >192.168.1.1< 更改为 >192.168.1.2<
[2024-01-01 12:10:01] [INFO] [DDNS-Docker] Api更新成功
```

日志级别说明:
- **DEBUG (0)**: 调试信息,包含API请求URL、返回详情等(适合故障排查)
- **INFO (1)**: 正常操作信息(默认级别),包括IP变化、更新成功等
- **WARN (2)**: 警告信息
- **ERROR (3)**: 错误信息,输出到stderr

查看容器日志:
```bash
# 查看实时日志
docker logs -f ddns

# 查看最近100行日志
docker logs --tail 100 ddns

# 仅查看错误日志
docker logs ddns 2>&1 | grep ERROR
```

#### 创建容器示例

##### 基础示例(无代理)
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -d namesiloddns:vx.x
```

##### 多主机名示例
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns,www,home" \
    -e APIKEY="your_api_key_here" \
    -d namesiloddns:vx.x
```

##### 使用SOCKS5代理
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e PROXY="socks5://192.168.1.1:1080" \
    -d namesiloddns:vx.x
```

##### 使用HTTP代理
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e PROXY="http://192.168.1.1:8080" \
    -d namesiloddns:vx.x
```

##### 使用HTTPS代理
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e PROXY="https://proxy.example.com:3128" \
    -d namesiloddns:vx.x
```

##### 自定义检查间隔和超时时间
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e LOOPTIME="5" \
    -e UTO="10" \
    -d namesiloddns:vx.x
```

##### 强制使用代理模式
```bash
docker run --name ddns -t \
    -e DOMAIN="example.com" \
    -e HOST="ddns" \
    -e APIKEY="your_api_key_here" \
    -e PROXY="socks5://192.168.1.1:1080" \
    -e PROXY_MODEL="2" \
    -d namesiloddns:vx.x
```

##### 挂载日志文件到宿主机(可选)
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
    -e LOG_FILE="/ddns.log" \
    -v /var/log/ddns.log:/ddns.log \
    -d namesiloddns:vx.x
```

## 工作原理

容器启动后会执行以下流程:

1. **初始化**: 读取环境变量配置
2. **获取公网IP**: 依次尝试多个公网IP查询接口(Amazon、ipify、ifconfig.me、my-ip.io)
3. **代理检测**: 根据PROXY_MODE决定使用直连还是代理访问Namesilo API
   - PROXY_MODEL=0: 先测试直连是否可达,不可达时使用代理
   - PROXY_MODEL=1: 始终使用直连
   - PROXY_MODEL=2: 始终使用代理(需设置PROXY环境变量)
4. **获取DNS记录**: 从Namesilo API获取当前域名的所有A记录
5. **比对IP**: 将获取的公网IP与DNS记录中的IP进行比对
6. **更新DNS**: 如果IP不同,则调用API更新对应的A记录
7. **循环执行**: 等待LOOPTIME分钟后重复步骤2-6

## 注意事项

### 1. API调用频率限制
- Namesilo API有调用频率限制,建议 `LOOPTIME` 设置为 **15分钟或以上**
- 过短的检查间隔可能导致API被临时封禁
- 每次循环会调用2次API(dnsListRecords + dnsUpdateRecord),请合理设置检查间隔

### 2. 网络环境
- 确保容器能够访问外网以获取公网IP
- 如果在企业内外网隔离环境,则无法使用本项目,请将容器移入DMZ区域
- 支持的公网IP获取接口会自动切换(Amazon、ipify、ifconfig.me、my-ip.io)
- PROXY_MODEL=0时会自动检测直连是否可用,不可用时才使用代理

### 3. DNS记录要求
- **必须提前在Namesilo控制台创建对应的A记录**
- HOST参数填写的是A记录的前缀,不是完整域名
- 例如:要为 `ddns.example.com` 更新DNS,则 `DOMAIN=example.com`,`HOST=ddns`
- **支持同时更新多个A记录**,HOST参数用逗号分隔,如: `HOST="ddns,www,home"`

### 4. 时区设置
- 务必正确设置 `TZ` 参数,否则日志时间可能不准确
- 常用时区参考:
  - 中国标准时间: `Asia/Shanghai`(默认)
  - 日本标准时间: `Asia/Tokyo`
  - 美国东部时间: `America/New_York`
  - UTC时间: `UTC`

### 5. 日志管理
- 默认日志输出到容器stdout/stderr,可通过 `docker logs` 查看
- ERROR和WARN级别日志会同时输出到stderr
- 如需持久化日志,可挂载日志文件到宿主机并通过`LOG_FILE`设置日志文件路径
- 建议定期清理或轮转日志文件,避免占用过多磁盘空间
- 故障排查时可将LOG_LEVEL设置为0以查看详细的API请求和响应

### 6. 安全建议
- **不要将APIKey硬编码在脚本中**,始终通过环境变量传递
- 不要在公开场合分享包含APIKey的日志或配置文件
- 定期轮换APIKey以提高安全性
- 考虑使用Docker secrets或外部密钥管理服务存储敏感信息
- DEBUG级别日志会显示完整的API URL(包含APIKey),生产环境建议使用INFO级别

### 7. 代理配置

#### 代理格式说明
- PROXY参数格式: `"协议://IP:端口"`
- **重要**: 必须包含协议前缀(如 `socks5://`, `http://`)
- 示例:
  - SOCKS5代理: `socks5://192.168.1.1:1080`
  - HTTP代理: `http://192.168.1.1:8080`
  - HTTPS代理: `https://proxy.example.com:3128`
  - SOCKS4代理: `socks4://192.168.1.1:1080`

#### 代理模式说明
- **PROXY_MODEL=0 (智能模式)**: 
  - 先测试直连Namesilo API是否可达
  - 如果直连失败且设置了PROXY,则自动切换到代理模式
  - 推荐大多数用户使用
  
- **PROXY_MODEL=1 (强制直连)**:
  - 始终使用直连方式访问API
  - 即使设置了PROXY也不会使用
  - 适用于网络环境良好的场景
  
- **PROXY_MODEL=2 (强制代理)**:
  - 始终使用代理访问API
  - **必须设置PROXY环境变量**,否则无法正常工作
  - 适用于必须通过代理访问的场景

#### 技术实现
- 使用curl原生的 `-x` 参数实现代理功能
- 支持所有curl支持的代理协议

### 8. 故障排查

#### 问题1: 容器启动后立即退出
```bash
# 查看容器日志
docker logs ddns

```

#### 问题2: 无法获取公网IP
```bash
# 进入容器测试网络连接
docker exec -it ddns /bin/bash
curl -v https://checkip.amazonaws.com

# 修改临时环境变量
export UTO="15"

# 修改DEBUG日志等级
export LOG_LEVEL="0"

# 启动脚本测试
./namesiloddns-dk.sh
```

#### 问题3: API更新失败
```bash
# 查看详细日志
docker logs ddns | grep ERROR

# 检查APIKey是否有效
# 检查域名和主机名是否正确
# 确认A记录已存在
# 检查PROXY_MODEL设置是否合适

# 进入容器使用DEBUG模式查看API返回
# 修改DEBUG日志等级
export LOG_LEVEL="0"

# 启动脚本测试
./namesiloddns-dk.sh
```

#### 问题4: 多个主机名只有部分更新
```bash
# 检查HOST参数格式是否正确(逗号分隔,无空格)
-e HOST="ddns,www,home"

# 查看每个主机名的处理日志
docker logs ddns | grep "当前进行主机"

# 确认Namesilo控制台中所有A记录都已创建

# 进入容器使用DEBUG模式查看API返回
# 修改DEBUG日志等级
export LOG_LEVEL="0"

# 启动脚本测试
./namesiloddns-dk.sh
```

#### 问题5: 代理模式下仍然连接失败
```bash
# 检查DOCKER启动命令PROXY格式是否正确(必须包含协议前缀)
-e PROXY="socks5://192.168.1.1:1080"

# 检查代理服务器是否可达
docker exec -it ddns /bin/bash
curl -v -x socks5://192.168.1.1:1080 https://www.namesilo.com

# 强制使用代理模式
export PROXY_MODEL="2"

# 修改DEBUG日志等级
export LOG_LEVEL="0"

# 启动脚本测试
./namesiloddns-dk.sh
```

#### 问题6: 日志显示状态码为空或JSON解析错误
- 可能是API返回格式异常
- 设置 `LOG_LEVEL=0` 查看API返回的原始内容
- 检查网络连接是否正常
- 确认APIKey是否有权限访问该域名

#### 问题7: PROXY参数格式错误导致代理不生效
```bash
# 错误示例(缺少协议前缀):
-e PROXY="192.168.1.1:1080"

# 正确示例(包含协议前缀):
-e PROXY="socks5://192.168.1.1:1080"
-e PROXY="http://192.168.1.1:8080"

# 代理服务器需要用户名和密码
-e PROXY="socks5://user:pass@192.168.1.1:1080"
-e PROXY="https://user:pass@proxy.example.com:3128"
```

### 9. 容器管理

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

# 进入容器内部(调试用)
docker exec -it ddns /bin/bash

# 查看容器资源使用情况
docker stats ddns

# 查看容器详细配置
docker inspect ddns
```