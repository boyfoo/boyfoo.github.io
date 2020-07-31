---
layout: post
title: 'docker swarm 集群部署02'
date: 2020-07-31
author: boyfoo
tags: docker swarm
---

docker 加入 swarm 集群后 允许本地和集群两种
```bash
# 本地运行
docker run ...
# 节点运行
docker server ...
```

#### 运行一个示例

```bash
# 会在集群中任意一个节点运行名为web_server的服务 (默认一个副本)
docker service create --name web_server httpd

# replicas指定需要几个副本
docker service create --name web_server --replicas 2 httpd


# 查看集群中的运行的服务(一个服务可能运行多个容器，只显示一条)
docker service ls

###
ID                  NAME                MODE                REPLICAS            IMAGE               PORTS
oipx9tiqw9cx        web_server          replicated          1/1                 httpd:latest


# 查看集群中具体服务有哪些容器 列出一个服务的所有容器
docker service ps  web_server
```

可以通过图形化界面直接了然的看到

副本伸缩

```
# 将web_server服务 副本选择为5个
docker service scale web_server=5

# 该为3个
docker service scale web_server=3
```

副本所在节点会平均的随机开

如果希望某一个节点不加入，如主节点只想管理worker节点 不想运载容器

```bash
# 将 node1 节点排除集群运算
docker node update --availability drain node1

# 查看节点状态 此时节点node1状态为 drain 
docker node ls
```

排除在集群编码时，被排除节点上原本运行的容器会停止 (不是删除，缩容的时候是删除)，其他节点会根据副本指定数量重新补全

```bash
# 查看容器状态 原本node1 上的副本name之前出现 \_ web_server.2 状态为 Shutdown
docker service ps web_server
```


```
# 从新激活 加入集群编排
docker node update --availability active node1
```

重新加入编排的时候不会让副本从新分配，之前节点drain时关闭的副本也不能重启

删除服务

```bash
docker service rm web_server
```

删除服务会删除所有该服务的容器

#### 外部访问 server

查看服务的网卡ip

```bash
# 后面跟着容器的名称
docker inspect web_server.3.99rrplk9uxtt3zf0ada3mgwwd | grep IPAddress
```

返回的ip为本地docker0网卡的桥接地址 只能在宿主机上访问

要提供外网访问 需要端口映射

```bash
docker service update --publish-add 8080:80 web_server
```

把节点8080端口映射到web_server服务中

```bash
# 可以看到服务后面多少端口映射信息
docker service ls
```

集群会把该服务旧的副本关闭 并从新创建新的副本并映射对应的接口

所有节点都会把8080的端口映射到web_server服务80中

这个映射是针对整个集群 集群中任意节点访问8080端口都会代理到服务web_server中，就算这个节点没有运行该服务的副本 

#### server 之间通信