---
layout: post
title: 'helm3 和 nginx-ingress安装'
date: 2021-01-02
author: boyfoo
tags: k8s
---

### 安装

下载 `wget https://get.helm.sh/helm-v3.4.2-linux-amd64.tar.gz`

解压 `tar -xzvf helm-v3.4.2-linux-amd64.tar.gz`

移动至 `mv helm /usr/local/bin/`

设置微软仓库地址 `helm repo add stable http://mirror.azure.cn/kubernetes/charts/`

更新仓库索引 `helm repo update`

### 部署服务

查看是否存在:

```bash
$ helm search repo mysql
```

安装服务:

```bash
# helm install [服务名称] [仓库镜像名称]
$ helm install mydb-mysql stable/mysql
```

查看已安装服务:

```bash
# helm list -n [命名空间]
$ helm list 
```

删除服务:

```bash
$ helm uninstall mydb-mysql
```

#### 自定义服务

```bash
# 在当前目录创建一个叫mygin的项目
$ helm create mygin

# 查看创建结果
$ ls mygin
Chart.yaml  charts  templates   values.yaml

# 包含go模板
$ ls mygin/templates
NOTES.txt    _helpers.tpl    deployment.yaml    hpa.yaml    ingress.yaml    service.yaml    serviceaccount.yaml    tests


# 模板内容解析成yaml格式
# helm install [服务名称] [本地地址] --dry-run --debug
$ helm install abc mygin --dry-run --debug

# 确定部署
# helm install [服务名称] [本地地址]
$ helm install my-gin mygin
```

### nginx-ingress

什么是 `nginx-ingress`？

就是一个 `nginx` 的 `controller`，它监听了`ingress` 规则的变化，根据规则生成 `nginx.conf` 配置文件，写入对应的`pod` 中，然后 `reload`

安装 `nginx-ingress` 多种方法`https://kubernetes.github.io/ingress-nginx/deploy/`，此处选择使用 `helm` 安装

```bash
$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
$ helm repo update

$ helm install my-release ingress-nginx/ingress-nginx
# 会出现因不可描述原因下载镜像失败，处理方式: 查看是哪个imgaes下载失败，先 helm uninstall my-release，手动下载docker镜像，最后重新安装
```

下载 `helm` 仓库的 `ingress-nginx` 至本地编辑:

```
# 下载后并解压
$ helm fetch ingress-nginx/ingress-nginx  
```

编辑`value.yaml`文件:

```bash
# 修改网络类型为host网络
controller.hostNetwork = true
controller.hostPort.enabled = true
# 每个节点部署一个
controller.kind = DaemonSet 

# 会创建一个serveice 
controller.service.enabled = true
# 默认 controller.service.type = LoadBalancer 如果是虚拟机 没有外网ip可能会造成服务部署状态一直是pending
# 若要解决虚拟机问题进行一下修改 start
controller.service.type = NodePort
controller.service.nodePorts.http = 32080
controller.service.nodePorts.https = 32443
# end

controller.admissionWebhooks.enabled = false
```

安装，此时使用本地修改过的 ingress-nginx 文件夹内容安装:
```bash
# 安装
$ helm install my-release ingress-nginx 
# 更新
$ helm upgrade my-release ingress-nginx 
```
