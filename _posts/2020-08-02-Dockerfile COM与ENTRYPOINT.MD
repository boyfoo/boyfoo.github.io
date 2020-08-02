---
layout: post
title: '2020-08-02-Dockerfile COM与ENTRYPOINT'
date: 2020-08-02
author: boyfoo
tags: docker
---


### CMD

CMD 适用于docker run 时，没有指定运行的命令而**默认**执行的命令，CMD的命令结束时，容器也终止，不过可以被docker run 后指定的命令覆盖

#### CMD 三种格式 

1. CMD <command> 
2. CMD ["<executable>", "<param1>", "<param2>"]
3. CMD ["<param1>", "<param2>"]

**第1种**是以 `/bin/sh -c` 的形式来运行`<command>`内容，意味着`<command>`对应的进程的pid不为1，是做为`/bin/sh`的子进程运行，当使用`docker stop <container> ` 命令停止时，`<command>`进程接受不到系统发送来的 `SIGTERM` 等信号

如 `CMD /bin/httpd` 主进程是`sh` 子进程是 `httpd` 

**第2种**形式 以 `<executable>` 内的为运行的命令为主进程，后面为参数，不会已`/bin/sh -c`来运行，因此常见的shell 操作如变量替换以及通配符(?,*)替换将不会进行，如果还是需要此特性的话，可以使用 `CMD ["/bin/bash", "-c", "<executable>", "<param1>"]` 运行，但这样做会遇到跟第1种一样的问题

**第3种** 是为 `ENTRYPOINT` 提供**默认**参数


#### 示例

main.go 文件：

```go 
package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

func main() {

	fmt.Println("启动")
	sigs := make(chan os.Signal, 1)
	done := make(chan bool, 1)

	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	f, e := os.OpenFile("log.test", os.O_CREATE|os.O_RDWR, os.ModeAppend)
	if e != nil {
		fmt.Println(e)
	}
	defer f.Close()

	go func() {
		<-sigs
		n, er := f.Write([]byte("接受到停止信号"))
		fmt.Println(n, er)
		f.Close()
		done <- true
	}()

	<-done
}
```


```bash
FROM golang:1.13

LABEL maintainer="Zhengxin <zx358317301@qq.com>"

# .所在目录是main.go文件所在目录
COPY . /data/go/

WORKDIR /data/go/

RUN go build -o testrun

#方式一 CMD ./testrun
CMD ["./testrun"]
```

使用方式1 `CMD ./testrun` 无法触发中断信号接受的代码


### ENTRYPOINT 

与`CMD`不同，`CMD`可以被`docker run`后指定的参数覆盖，`ENTRYPOINT`无法覆盖，只会将`docker run`后指定的参数当成参数传给`ENTRYPOINT`

如果依旧想覆盖自带的，可以使用 `--entrypoint`
```bash
docker run --entrypoint xxx httpd
```


如果 `CMD` 与 `ENTRYPOINT` 同时定义了，`CMD`会被当成参数传给`ENTRYPOINT`