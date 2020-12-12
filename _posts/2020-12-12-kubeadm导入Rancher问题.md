---
layout: post
title: 'kubeadm 导入 Rancher 问题'
date: 2020-12-12
author: boyfoo
tags: k8s
---

在 `Rancher` 面板出现 `controller-manager ` 和 `scheduler` 不健康


查看组件情况:

```apacheconfig
$ kubectl get cs
```

若出现 `Unhealthy` 状态，修改配置文件

```apacheconfig
vim /etc/kubernetes/manifests/kube-scheduler.yaml
vim /etc/kubernetes/manifests/kube-controller-manager.yaml

# 将两个文件的 --port=0 注释 
# 然后从新启动
$ systemctl restart kubelet
```
