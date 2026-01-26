---
title: Ubuntu配置Aria2
date: 2026-01-12
updated: 2026-01-13
tags: [Linux tools, aria2, proxy]
categories: Linux
description: Linux下aria2的配置
---

#### docker-compose设置代理

每次配置docker环境都要google查询资料配置代理，实在是麻烦费时。干脆记录一下配置方法，后面再也不想花大把时间配环境了。

此处主要是`docker-compose`的代理，适用于通过`docker-composer`启动的项目：

在`docker-compose.yaml`文件中的`environment`字段增加`HTTP_PROXY`和`HTTPS_PROXY`，例如：

```yaml
services:
  comfyui:
    image: "test:latest"
    container_name: "test"
    restart: always
    ports:
      - "8080:8080"
    environment:
      - HTTPS_PROXY=http://127.0.0.1:7890
      - HTTP_PROXY=http://127.0.0.1:7890
```

可能需要重启`docker`服务才能有效，也可能需要重启终端。
