---
layout: post
title: '加密算法和openssl与CA签证'
date: 2021-01-04
author: boyfoo
tags: 其他
---
#### HASH算法 (不可逆)

`MD5` `SHA1` `SHA256` 等都算是`HASH`算法

#### 对称加密 (可逆)

双向加密算法和协议:
1. DES 已过时，可破解
2. 3DES 已过时，DES基础上已久属于可破解
3. AES 当前流行

特性:
1. 加密，解密同一个密钥
2. 原始数据分割成固定大小块，逐个加密

缺陷:
1. 密钥过多
2. 密钥分发困难，任何人偷窥到密钥就可以加密解密数据

#### 公钥加密 (可逆)

密钥分为私钥和公钥

私钥通过工具创建，使用者自己保存，必须保持其私密性

公钥可以公开给所有人，pubkey (公钥从私钥中提取产生)

特点: 公钥加密的数据，只能用与之配对的私钥解密；私钥加密的数据，所有的公钥都可以解密；所以只保护了公钥方发给私钥方的消息的保密性，而私钥方放给公钥方的消息所有人都可以解密，是不保密性的，但是不能篡改消息，因为篡改后公钥无法解密。保证了数据的完整性和身份认证，但是没有保密性

用途:
1. 数字签名: 让接收方确认发送方的身份
2. 密钥交换: 发送方用对方公钥加密一个对称密钥，发送给对方
3. 数据加密

公钥加密算法:
1. RSA
2. DSA
3. ELGamal (商业)


单向加密:

    特性: 定长输出，雪崩效应(数据微小改变，加密结果巨大变化)
    算法: md5,sha1,sha224,sha256,sha384,sha512

数字证书格式标准: X.509


### openssl

开源命令行工具
    1. 标准命令 `$ openssl`
    2. 消息摘要命令 `$ openssl dgst`
    3. 加密命令 `$ openssl enc`

#### 对称加密 `enc` 命令

```bash
# 加密
# -e 加密行为 
# -des-ede3-cbc 使用des-ede3-cbc加密算法
# -a base64编码结果 不然是二进制
# -in 输入内容
# -out 输出内容
$ openssl enc -e -des-ede3-cbc -a -in int.txt -out out.txt
# 解密
# -d解密行为
$ openssl enc -d -des-ede3-cbc -a -in out.txt -out int.txt
```

#### 单向加密 `dgst` 命令

```bash
$ openssl dgst -md5 in.txt
```

#### 公钥加密

生成私钥

```bash
# 使用RSA算法 密钥长度1024
$ openssl genrsa 1024 > test.private
# 结果同上一样
$ openssl genrsa -out test.private 1024
```

从私钥提取公钥

```bash
# -in 私钥文件
# -pubout 提取行为
$ openssl rsa -in test.private -pubout
```

#### CA

查看`openssl`配置目录：`openssl version -a`

获得目录为 `/usr/lib/ssl`

查看配置文件 `vim openssl.cnf`

```bash
# 默认配置环境
[ CA_default ]
dir # 工作目录
certs # 已经颁发过的证书
crl_dir # 已经吊销的证书
database # 各个已经颁发证书的索引(每个证书都有一个属于自己的唯一序列号)

certificate # ca的自签证书 (自己给自己发证)
serial # 当前如果颁发证书的序列号 类似mysql主键自增

private_key # ca自己的私钥
```

#### 构建私有`CA`:

1. 签证服务器为`CA`生成自己的私钥: 

```bash
# 文件名称与 配置文件内的 private_key 要相同
$ openssl genrsa -out /usr/lib/ssl/private/cakey.pem 4096
```

2. 签证服务器自签`CA`根证书

```bash
# req 请求证书
# -new 生成新证书签署请求
# -key 指定一个私钥 原则上不能用私钥去请求证书，所以这个行为会自动从私钥中抽取公钥出来放到请求里 
# -out 输出位置，与配置文件内 certificate 值相同
# -days 证书过期时间
# -x509 生成自签格式证书，专用于创建私有CA时，现在是自己请求自己给自己自签证书，自签就要加-x509
$ openssl req -new -x509 -key /usr/lib/ssl/private/cakey.pem -out /usr/lib/ssl/cacert.pem -days 365

# 提供所需的目录与文件
$ mkdir certs crl newcerts
$ touch /usr/lib/ssl/{serial,index.txt}
$ echo 01 > /usr/lib/ssl/serial
```

以上为构建`ssl`签证服务器步骤，之后是其他服务器请求办法证书

3. web服务器请求签证

```bash
# 生成一个私钥
$ openssl genrsa -out httpd.key 2048

# 生成一个请求签证的csr文件 csr只是生成证书的中间文件 使用后可删除
$ openssl req -new -key httpd.key -out httpd.csr
```

将`csr`文件发送至签证服务器，在签证服务器执行证书签证操作:

```bash
# 生成crt文件 此后所有服务器上的csr文件可以通通删除了 并将crt证书文件发送回给web服务器
$ openssl ca -in httpd.csr -out httpd.crt
```

4. 查看正式签证信息

```
$ openssl x509 -in httpd.crt -noout -serial -subject
$ openssl x509 -in cacert.pem  -noout -serial -subject
```