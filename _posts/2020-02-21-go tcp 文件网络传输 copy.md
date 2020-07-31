---
layout: post
title: 'go tcp 文件网络传输'
date: 2020-02-21
author: boyfoo
tags: golang
---

使用 tcp 协议分片传输数据

### 发送端

```go
func main() {

	filePath := "xxx/xxx.xx"
	// 获取文件信息
	f, err := os.Stat(filePath)
	if err != nil {
		fmt.Println(err)
		return
	}
	fileName := f.Name()

	// 主动发起连接
	conn, err := net.Dial("tcp", "127.0.0.1:8008")
	if err != nil {
		fmt.Println(err)
		return
	}

	defer conn.Close()

	// 发送文件名
	_, err = conn.Write([]byte(fileName))
	if err != nil {
		fmt.Println(err)
		return
	}

	// 服务器返回ok
	buf := make([]byte, 16)
	n, err := conn.Read(buf)
	if err != nil {
		fmt.Println(err)
		return
	}

	if "ok" == string(buf[:n]) {
		// 写文件给服务端
		sendFile(conn, filePath)
	}

}

func sendFile(conn net.Conn, filePath string) {
	// 只读打开文件
	f, err := os.Open(filePath)
	if err != nil {
		fmt.Println(err)
		return
	}

	defer f.Close()

	// 重本地文件中 每次读4m 写给接收端
	buf := make([]byte, 4096)
	for {
		n, err := f.Read(buf)
		if err != nil {
			if err == io.EOF {
				fmt.Println("发送文件完毕")
			} else {
				fmt.Println(err)
			}
			return
		}

		// 写到网络中
		_, err = conn.Write(buf[:n])
		if err != nil {
			fmt.Println(err)
			return
		}
	}
}
```

### 接收端

```go
func main() {

	// 创建监听
	listener, err := net.Listen("tcp", "127.0.0.1:8008")
	if err != nil {
		fmt.Println(err)
		return
	}
	defer listener.Close()

	conn, err := listener.Accept()
	if err != nil {
		fmt.Println(err)
		return
	}
	defer conn.Close()

	// 读取文件名
	buf := make([]byte, 4096)
	n, err := conn.Read(buf)

	fileName := string(buf[:n])
	if err != nil {
		fmt.Println(err)
		return
	}

	// 回写ok给发送端
	conn.Write([]byte("ok"))

	// 获取文件内容
	recvFile(conn, fileName+".bak")
}

func recvFile(conn net.Conn, fileName string) {
	// 创建新文件
	f, err := os.Create(fileName)
	if err != nil {
		fmt.Println(err)
		return
	}

	defer f.Close()

	// 从网络中读取数据 写入本地文件
	buf := make([]byte, 4096)
	for {
		n, _ := conn.Read(buf)
		if n == 0 {
			fmt.Println("接受文件完成")
			return
		}

		f.Write(buf[:n])
	}
}
```