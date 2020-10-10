---
layout: post
title: 'docker flannel'
date: 2020-10-10
author: boyfoo
tags: docker
---

关闭 firewalld 与 selinux

```bash
$ systemctl stop firewalld
$ systemctl disable firewalld

// 此操作只是临时关闭
$ setenforce 0  
```

添加etcd基本信息 (flannel需要etcd v2版本接口 ) 

```bash
# 网络节点为10.3.0.0 最小ip10.3.20.0 最大10.3.100.0
$ etcdctl set '/flannel/network/config' '{"Network": "10.3.0.0/16", "SubnetLen": 24, "SubnetMin": "10.3.20.0", "SubnetMax": "10.3.100.0", "Backend": {"Type": "vxlan"}}'
```

下载安装 flannel 

```bash
#下载
$ wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz
# 解压 出现flanneld mk-docker-opts.sh  README.md 三个文件
$ tar -xzvf flannel-v0.11.0-linux-amd64.tar.gz

#复制文件
$ sudo cp flanneld /usr/local/bin/
$ sudo cp mk-docker-opts.sh /usr/local/bin/
```

编写 systemd 文件

```bash
sudo vim /lib/systemd/system/flanneld.service

#内容
[Unit]
Description=Flanneld

[Service]
User=root
ExecStart=/usr/local/bin/flanneld -etcd-endpoints=http://192.168.10.10:2379 -etcd-prefix=/flannel/network

ExecStartPost=/usr/local/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker

Restart=on-failure
[Install]
WantedBy=multi-user.target
```

```bash
$ sudo systemctl daemon-reload
# 可能只需失败 报没有权限 先执行这个 然后取消 sudo /usr/local/bin/flanneld -etcd-endpoints=http://192.168.10.10:2379 -etcd-prefix=/flannel/network
$ sudo systemctl start flanneld.service

# 查看是否允许成功
ps -ef | grep flan
```



### docker 启动设置

...