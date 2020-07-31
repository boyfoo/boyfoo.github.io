---
layout: post
title: 'go consul 注册服务与反注册服务'
date: 2020-06-13
author: boyfoo
tags: consul
---

使用 docker-compose 运行

```bash
version: "3"

services:
  consul:
    image: consul
    ports:
    - 8500:8500
    command: agent -server -bind=0.0.0.0 -client=0.0.0.0 -bootstrap -ui

  #http://127.0.0.1:8500/ 访问ui界面
  #-server 会保存数据 -dev 开发模式 关闭后数据会消失
```

consul包
```go
go get github.com/hashicorp/consul
```

主运行文件 main.go
```go

import (
	"github.com/hashicorp/consul/api"
  ...
)

func main() {
  // 其他代码
  ...
  var ConsulClient *api.Client
  config := api.DefaultConfig()
  config.Address = "192.168.0.124:8500" // consul地址
  client, err := api.NewClient(config)
  if err != nil {
    log.Fatal(err)
  }

  go func() {
      reg := &api.AgentServiceRegistration{}
      reg.ID = "userseivice"  // 本服务id
      reg.Name = "userseivice"
      reg.Tags = []string{"primary"}  
      reg.Address = "192.168.0.124" // 本服务地址
      reg.Port = 8080 // 本服务端口
      reg.Check = &api.AgentServiceCheck{
        HTTP:     "http://192.168.0.124:8080/health", // consul 检测本服务存活的接口 返回 {"status":"ok"}
        Interval: "5s",   // 5s 检查一次
      }
      // 请求注册
      err := ConsulClient.Agent().ServiceRegister(reg)
      if err != nil {
        log.Fatal(err)
      }

      // 运行服务 此处举例为http服务
      err := http.ListenAndServe(":8080", r)
      if err != nil {
        errChan <- err
      }
    }()

    go func() {
      sig := make(chan os.Signal)
      signal.Notify(sig, syscall.SIGINT, syscall.SIGTERM)

      errChan <- fmt.Errorf("%s", <-sig)
    }()

  err := <-errChan
  // 反注册
  ConsulClient.Agent().ServiceDeregister("userseivice")
  fmt.Println(err)
}
```