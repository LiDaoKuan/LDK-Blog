---
title: 给git push和git pull设置代理
date: 2026-01-20
updated: 2026-01-20
tags: [Linux tools, git, proxy]
categories: Linux
description: git设置ssh代理
---

### git设置ssh代理

主要是方便`git push`和`git pull`走代理。
 
Linux端：

编辑`~/.ssh/config`文件，没有则创建一个：

```
Host github.com
    Hostname github.com
    # Port 443
    Port 22
    User git
    ProxyCommand nc --proxy-type socks5 --proxy 127.0.0.1:7890 %h %p
```

> windows的配置方法略有不同：

下面的配置**未在**windwos端测试。

```
Host github.com
User git
Hostname ssh.github.com
PreferredAuthentications publickey
IdentityFile ~/.ssh/id_rsa
Port 22
ProxyCommand connect -S 127.0.0.1:7890 %h %p
```