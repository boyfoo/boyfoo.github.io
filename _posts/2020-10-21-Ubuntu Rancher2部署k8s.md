---
layout: post
title: 'Ubuntu Rancher2 部署 k8s'
date: 2020-10-21
author: boyfoo
tags: k8s
---

#### 关闭防火墙

```bash
$ systemctl stop firewalld && systemctl disable firewalld
```
#### 关闭 SElinux

```bash
# 临时关闭 重启无效
$ setenforce 0 
```

#### 关闭 swap

```bash
$ swapoff -a
```

#### 重载配置

```bash
$ sudo systemctl daemon-reload && sudo systemctl restart docker
```

#### 主服务安装 rancher 

安装 rancher 稳定版，在主节点或者专门的 rancher 节点

```bash
$ sudo docker run -d -p 8080:80 -p 8443:443 -v /home/vagrant/rancher/:/var/lib/rancher rancher/rancher:stable
```

#### 新建集群

登录 rancher 外网，设置初始化账号，默认密码`admin`

<img src="/assets/img/post/rancher2/001.gif">

勾选对应机器对应的角色，并运行指令，最后点击完成，等待机器准备

若网络有问题，需要选择**显示高级选项**并且填写公网地址

此时集群状态显示 `Provisioning`，若显示`ETCD`相关失败原因可以删除集群，重新创建一个

