---
layout: post
title: '执行docker命令遇到 Get Permission Denied'
date: 2020-05-15
author: boyfoo
tags: docker
---

解决 linux 用户执行 docker 权限问题

```bash
sudo groupadd docker     #添加docker用户组
sudo gpasswd -a $USER docker     #将登陆用户加入到docker用户组中
newgrp docker     #更新用户组
docker ps    #测试docker命令是否可以正常使用
```