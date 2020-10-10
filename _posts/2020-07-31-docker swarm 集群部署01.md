---
layout: post
title: 'docker swarm 集群部署01'
date: 2020-07-31
author: boyfoo
tags: docker swarm
---

#### 宿主机配置

登录各自机器，修改三台主机名称(此处名称只为操作方便 与hosts的名称无因果关系):
```bash
sudo hostname node1 && bash

sudo hostname node2 && bash

sudo hostname node3 && bash
```

修改各自机器的 hosts 文件:
```bash
sudo vim /etc/hosts

192.168.10.10 node1
192.168.10.20 node2
192.168.10.30 node3
```

#### 创建集群

```bash
# node1
# 初始化集群 给与一个添加地址 默认成为管理节点加入
docker swarm init --advertise-addr 192.168.10.10

# 使用返回的返回token
# node2 以【工作节点】加入集群
docker swarm join --token SWMTKN-1-0rfd9w5o6bue7zpmmvu6i09yegcidlyx7zo16g8tttrg6wxqub-64e62sreaya8t13zu9jsdy58l 192.168.10.10:2377

# node3 以【工作节点】加入集群
docker swarm join --token SWMTKN-1-0rfd9w5o6bue7zpmmvu6i09yegcidlyx7zo16g8tttrg6wxqub-64e62sreaya8t13zu9jsdy58l 192.168.10.10:2377
```

该 token 24消失内有效，若过去可重新获取：
```bash
# 获取工作节点的加入token
docker swarm join-token worker

# 获取管理节点的加入token
docker swarm join-token manager
```


#### 查看 docker swarm 集群信息

将node1 node3设置为管理节点 node2 为工作节点

查看信息

```bash
docker info 

###
 Swarm: active
  NodeID: 1vjklo2g6meu0ergntm0wng0e
  Is Manager: true  #是否管理节点
  ClusterID: iho0jgvus3ffsld8fdpu6fs32
  Managers: 2   #2台管理节点
  Nodes: 3 #3个节点
  ...
 Node Address: 192.168.10.10 #当前节点ip
 Manager Addresses: # 管理节点的ip
   192.168.10.10:2377
   192.168.10.30:2377

```

在管理节点上查看集群节点信息：

```bash
docker node ls


###
节点id                          主机名             节点状态             是否使用             管理状态 (leader为管理节点中选出的领导)
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
7mfzrh8kant1hnh9l2o58wyrt *   node1               Ready               Active              Leader              19.03.6
xvvx4h7lfys0rgnxl5rxyr0x1     node2               Ready               Active                                  19.03.6
iuv2bqgukc268wzdjgwec4o1k     node3               Ready               Active              Reachable           19.03.6
```

节点身份

```bash
# 将node2节点提生为管理节点
docker node promote node2

# 讲node3降级为工作节点
docker node demote node3
```

创建网络
```bash
docker network create --driver overlay docker-swarm-test
```

#### 一个简单的docker swarm 图形化界面

```bash
docker run -itd -p 8888:8080 -e HOST=192.168.10.10 -e PORT=8080 -v /var/run/docker.sock:/var/run/docker.sock --name visualizer dockersamples/visualizer
```