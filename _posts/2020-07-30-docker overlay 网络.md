---
layout: post
title: 'docker overlay 网络'
date: 2020-07-03
author: boyfoo
tags: docker
---

镜像
```bash
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io
```

#### 安装consul
```bash
docker pull progrium/consul

docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp -h consul progrium/consul -server -bootstrap -ui-dir /ui

# 访问
http://192.168.10.10:8500/
```

#### 修改docker启动配置
```bash
sudo vim /lib/systemd/system/docker.service

ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0 --containerd=/run/containerd/containerd.sock --cluster-store=consul://192.168.10.10:8500 --cluster-advertise=eth1:2375

sudo systemctl daemon-reload

sudo systemctl restart docker.service
```

重启后打开conusul 访问 可以看到连接上的docker
```
http://192.168.10.10:8500/ui/#/dc1/kv/docker/nodes/
```


#### *目前在Homestead测试，不需要这步也可以使用

overlay 需要在 swarm 集群中使用 使用要在本机使用 要开启网卡混杂模式

```bash
# 开启对应网卡混杂模式
sudo ifconfig eth1 promisc

# 关闭
sudo ifconfig eth1 -promisc
```


还要开启路由转发功能
```bash
sudo vim /etc/sysctl.conf

net.ipv4.ip_forward=1
```

### 创建网络

```bash
docker network create --driver overlay --attachable ov_net1
```

此时在连接在一起cousul都会创建一个overlay网络

```bash
docker network inspect ov_net1

"IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    // 分配的地址
                    "Subnet": "10.0.0.0/24",  
                    "Gateway": "10.0.0.1"   
                }
            ]
},
```

运行一个容器
```bash
docker run -itd --name bbox1 --rm --network ov_net1  busybox:latest

# 查看容器网络
docker exec bbox1 ip r

// overlay 网络
10.0.0.0/24 dev eth0 scope link  src 10.0.0.2
// 桥接网络
172.18.0.0/16 dev eth1 scope link  src 172.18.0.2



# 查看网卡 会发现新建了一个docker_gwbridge桥接网络
# 这个桥接卡是为了让容器网络能连接到物理机上 可以访问到外网 而容器间通讯用 overlay 网卡
docker network ls

```
