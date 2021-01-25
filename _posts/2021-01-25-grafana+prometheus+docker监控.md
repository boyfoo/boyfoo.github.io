---
layout: post
title: 'grafana+prometheus+docker'
date: 2021-01-25
author: boyfoo
tags: docker linux 其他
---


### 安装 prometheus

默认配置文件

```yaml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']
```

```
docker run -v ./prometheus.yml:/etc/prometheus/prometheus.yml -p 9090:9090 prom/prometheus
```


### 安装 cAdvisor 监控docker

```
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor
```

在 `Ret Hat,CentOS, Fedora` 等发行版上需要传递如下参数，因为 `SELinux` 加强了安全策略：

`--privileged=true`

`http://127.0.0.1:8080 ` 查看页面，`/metric` 查看指标

### 安装 node-exporter 监控主机

```
docker run -d \
>   --net="host" \
>   --pid="host" \
>   --name=node-exporter \
>   -v "/:/host:ro,rslave" \
>   quay.io/prometheus/node-exporter \
>   --path.rootfs /host
```

访问 `:9100/metrics`  查看监控数据

### 修改 prometheus 配置

新增采集 `cAdvisor`  和 `node-exporter` 数据

```yaml
scrape_configs:
  ...
  - job_name: 'docker'
    static_configs:
    - targets: ['127.0.0.1:8080'] #默认http 默认'/metrics'路由
  - job_name: 'linux'
    static_configs:
    - targets: ['192.168.10.11:9100'] #默认http 默认'/metrics'路由
```

重启 `prometheus`


### 部署 grafana

```
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```

导入仪表盘 `193` (官方插件id，会直接从官网导入`cAdvisor`可用的模板) 点击 `load`

导入仪表盘 `9276` (官方插件id，会直接从官网导入`node-exporter`可用的模板) 点击 `load`

可能出现 网络进度带宽 内容无数据 可能是因为制定的网卡错误 点击`edit` 修改查询语句为：

```
# eth1 为被监控的服务器的网卡
irate(node_network_receive_bytes_total{instance=~'$node',device=~'eth1'}[5m])*8
```







