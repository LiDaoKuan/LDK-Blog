---
title: 给flatpak安装的应用设置代理
date: 2026-01-14
updated: 2026-01-15
tags: [Linux tools, flatpak]
categories: Linux日常使用
description: flatpak设置代理
---

#### 给flatpak安装的应用设置代理 

进入目标应用的沙箱环境：

```shell
flatpak run --command=sh 包名
```

包名查找：

```shell
flatpak list
```

在沙箱环境内设置代理：

```shell
gsettings set org.gnome.system.proxy mode manual
# 设置 HTTP 代理
gsettings set org.gnome.system.proxy.http host localhost
gsettings set org.gnome.system.proxy.http port 端口号
# 设置 HTTPS 代理
gsettings set org.gnome.system.proxy.https host localhost
gsettings set org.gnome.system.proxy.https port 端口号
# 设置 Socks 代理
gsettings set org.gnome.system.proxy.socks host localhost
gsettings set org.gnome.system.proxy.socks port 端口号
```

简洁版：

```shell
gsettings set org.gnome.system.proxy mode manual
gsettings set org.gnome.system.proxy.http host localhost
gsettings set org.gnome.system.proxy.http port 7890
gsettings set org.gnome.system.proxy.https host localhost
gsettings set org.gnome.system.proxy.https port 7890
gsettings set org.gnome.system.proxy.socks host localhost
gsettings set org.gnome.system.proxy.socks port 7890
```

