---
title: Ubuntu配置Aria2
date: 2026-01-12
updated: 2026-01-13
tags: [Linux tools, aria2, proxy]
categories: Linux
description: Linux下aria2的配置
---

#### 安装aria2

1. Ubuntu/Debian：

   ```shell
   sudo apt install 
   ```

2. CentOS/Fedora：

   ```shell
   sudo yum install aria2
   ```

3. Arch/Manjaro：

   ```shell
   sudo pacman -S aria2
   ```

#### 配置aria2

1. 创建配置文件：

   ```shell
   sudo mkdir /etc/aria2 
   sudo touch /etc/aria2/aria2.session 
   sudo chmod 755 /etc/aria2/aria2.session 
   sudo touch /etc/aria2/aria2.conf
   ```

2. 编辑配置文件：

   ```shell
   sudo vim /etc/aria2/aria2.conf
   ```

3. 配置文件内容：

   ```shell
   ## 全局设置 ## ============================================================
   # 日志
   #log-level=warn
   #log=/PATH/.aria2/aria2.log
   
   # 后台运行
   #daemon=true
   
   # 下载位置, 默认: 当前启动位置(***)
   dir=/home/***/ 下载
   
   # 从会话文件中读取下载任务(***)
   input-file=/etc/aria2/aria2.session
   
   # 在 Aria2 退出时保存 ` 错误 / 未完成 ` 的下载任务到会话文件(***)
   save-session=/etc/aria2/aria2.session
   
   # 定时保存会话, 0 为退出时才保存, 需 1.16.1 以上版本, 默认:0
   save-session-interval=30
   
   # 断点续传
   continue=true
   
   # 启用磁盘缓存, 0 为禁用缓存, 需 1.16 以上版本, 默认:16M
   #disk-cache=32M
   
   # 文件预分配方式, 能有效降低磁盘碎片, 默认:prealloc
   # 预分配所需时间: none < falloc ? trunc < prealloc
   # falloc 和 trunc 则需要文件系统和内核支持
   # NTFS 建议使用 falloc, EXT3/ 4 建议 trunc, MAC 下需要注释此项
   file-allocation=none
   # 客户端伪装
   user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.93 Safari/537.36
   
   # 禁用 IPv6, 默认:false
   disable-ipv6=true
   
   # 其他
   always-resume=true
   check-integrity=true
   
   ## 下载位置 ## ============================================================
   # 最大同时下载任务数, 运行时可修改, 默认:5
   max-concurrent-downloads=3
   
   # 同一服务器连接数, 添加时可指定, 默认:1
   max-connection-per-server=16
   
   # 最小文件分片大小, 添加时可指定, 取值范围 1M -1024M, 默认:20M
   # 假定 size=10M, 文件为 20MiB 则使用两个来源下载; 文件为 15MiB 则使用一个来源下载
   min-split-size=10M
   
   # 单个任务最大线程数, 添加时可指定, 默认:5
   split=64
   
   # 整体下载速度限制, 运行时可修改, 默认:0
   #max-overall-download-limit=0
   
   # 单个任务下载速度限制, 默认:0
   #max-download-limit=0
   
   # 整体上传速度限制, 运行时可修改, 默认:0
   #max-overall-upload-limit=0
   
   # 单个任务上传速度限制, 默认:0
   #max-upload-limit=0
   
   ## RPC 设置 ## ============================================================
   # 启用 RPC, 默认:false
   enable-rpc=true
   
   # 允许所有来源, 默认:false
   rpc-allow-origin-all=true
   
   # 允许非外部访问, 默认:false
   rpc-listen-all=true
   
   # 事件轮询方式, 取值:[epoll, kqueue, port, poll, select], 不同系统默认值不同
   #event-poll=select
   
   # RPC 监听端口, 端口被占用时可以修改, 默认:6800
   rpc-listen-port=6800
   
   # 设置的 RPC 授权令牌, v1.18.4 新增功能, 取代 --rpc-user 和 --rpc-passwd 选项
   #rpc-secret=
   
   # 是否启用 RPC 服务的 SSL/TLS 加密,
   # 启用加密后 RPC 服务需要使用 https 或者 wss 协议连接
   #rpc-secure=true
   
   # 在 RPC 服务中启用 SSL/TLS 加密时的证书文件,
   # 使用 PEM 格式时，您必须通过 --rpc-private-key 指定私钥
   #rpc-certificate=/path/to/certificate.pem
   
   # 在 RPC 服务中启用 SSL/TLS 加密时的私钥文件
   #rpc-private-key=/path/to/certificate.key
   
   ## BT/PT 下载相关 ## ============================================================
   # 当下载的是一个种子 (以.torrent 结尾) 时, 自动开始 BT 任务, 默认:true
   #follow-torrent=true
   
   # BT 监听端口, 当端口被屏蔽时使用, 默认:6881-6999
   listen-port=51413
   
   # 单个种子最大连接数, 默认:55
   #bt-max-peers=55
   
   # 打开 DHT 功能, PT 需要禁用, 默认:true
   enable-dht=false
   
   # 打开 IPv6 DHT 功能, PT 需要禁用
   #enable-dht6=false
   
   # DHT 网络监听端口, 默认:6881-6999
   #dht-listen-port=6881-6999
   
   dht-file-path=/opt/var/aria2/dht.dat
   dht-file-path6=/opt/var/aria2/dht6.dat
   
   # 本地节点查找, PT 需要禁用, 默认:false
   #bt-enable-lpd=false
   
   # 种子交换, PT 需要禁用, 默认:true
   enable-peer-exchange=false
   
   # 每个种子限速, 对少种的 PT 很有用, 默认:50K
   #bt-request-peer-speed-limit=50K
   
   # 设置 peer id 前缀
   peer-id-prefix=-TR2770-
   
   # 当种子的分享率达到这个数时, 自动停止做种, 0 为一直做种, 默认:1.0
   seed-ratio=0
   
   # 强制保存会话, 即使任务已经完成, 默认:false
   # 较新的版本开启后会在任务完成后依然保留.aria2 文件
   #force-save=false
   
   # tracker 地址，从以下地址获取的:
   # https://tk.sleele.com/
   # https://github.com/XIU2/TrackersListCollection
   # https://github.com/ngosang/trackerslist
   bt-tracker=http://tracker.internetwarriors.net:1337/announce,udp://tracker.opentrackr.org:1337/announce
   
   # BT 校验相关, 默认:true
   #bt-hash-check-seed=true
   
   # 继续之前的 BT 任务时, 无需再次校验, 默认:false
   bt-seed-unverified=true
   
   # 保存磁力链接元数据为种子文件(.torrent 文件), 默认:false
   bt-save-metadata=true
   
   bt-max-open-files=16
   
   # Http/FTP 相关
   connect-timeout=120
   
   ```

4. 开启RPC并设置密钥（可选）

   ```shell
   在配置文件中启用 RPC 并设置秘钥
   在 aria2.conf 中添加或修改以下内容：
   
   ini
   复制代码
   # 启用 RPC
   enable-rpc=true
   
   # 绑定的 IP 地址，0.0.0.0 表示允许所有 IP 地址连接
   rpc-listen-all=true
   
   # RPC 监听端口（默认是6800）
   rpc-listen-port=6800
   
   # 设置 RPC 的秘钥（token），这里用 "your-secret-token" 作为示例
   rpc-secret=your-secret-token
   
   # 允许远程访问
   rpc-allow-origin-all=true
   
   ```

#### 自启动服务

编辑服务文件：

```shell
sudo vim /etc/systemd/system/aria2c.service
```

内容：

```shell
[Unit]
Description= Aria2c Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/aria2c --conf-path=/etc/aria2/aria2.conf

[Install]
WantedBy=multi-user.target

```

开启服务并自启动：

```shell
# 更新配置
sudo systemctl daemon-reload

# 启动服务
sudo systemctl start aria2c

# 设置开机启动
sudo systemctl enable aria2c

```

服务管理：

```shell
# 启动服务
sudo systemctl start aria2c

# 停止服务
sudo systemctl stop aria2c

# 重启服务
sudo systemctl restart aria2c

# 查看状态
sudo systemctl status aria2c

```

###### 参考文章：

[JiFu's Wiki](https://jifu.nz/pages/544a06/#%E9%85%8D%E7%BD%AE%E5%86%85%E5%AE%B9).
