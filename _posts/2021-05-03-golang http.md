---
layout: post
title: 'golang http'
date: 2021-05-03
author: boyfoo
tags: golang
---

#### GET 请求

```go
func get() {
	request, err := http.NewRequest(http.MethodGet, "https://oa-api.517rxt.com/v1/auth/inspect", nil)

	if err != nil {
		log.Fatal(err)
	}

	// 添加url后面参数
	params := make(url.Values)
	params.Add("user_login_name", "18654444799")
	params.Add("type", "1")
	request.URL.RawQuery = params.Encode()
	// ?user_login_name=18654444799&type=1

	res, err := http.DefaultClient.Do(request)
	defer func() {
		_ = res.Body.Close()
	}()

	all, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println(string(all))
}
```

#### POST 请求

```go
func post() {
	{
		// form data
		data := make(url.Values)
		data.Add("name", "zx")
		data.Add("age", "9")

		post, _ := http.Post(
			"http://127.0.0.1:8000/api/test",
			"application/x-www-form-urlencoded",
			strings.NewReader(data.Encode()),
		)

		all, _ := ioutil.ReadAll(post.Body)
		fmt.Println(string(all))
	}

	{
		// json
		c := map[string]string{"zx": "name"}
		marshal, _ := json.Marshal(c)

		post, _ := http.Post(
			"http://127.0.0.1:8000/api/test",
			"application/json",
			bytes.NewReader(marshal),
		)

		all, _ := ioutil.ReadAll(post.Body)
		fmt.Println(string(all))
	}

	{
		// 文件
		body := new(bytes.Buffer)
		writer := multipart.NewWriter(body)
		_ = writer.WriteField("name", "zx")
		_ = writer.WriteField("age", "18")

		fileWriter, _ := writer.CreateFormFile("file_name", "file_name")

		openFile, _ := os.Open("go.mod")
		defer func() {
			_ = openFile.Close()
		}()

		_, _ = io.Copy(fileWriter, openFile)

		_ = writer.Close()

		post, _ := http.Post(
			"http://127.0.0.1:8000/api/test",
			writer.FormDataContentType(),
			body,
		)

		all, _ := ioutil.ReadAll(post.Body)
		fmt.Println(string(all))
	}
}
```

#### 编码

```go
func encoding() {
	r, err := http.Get("https://baidu.com")
	if err != nil {
		panic(err)
	}
	defer r.Body.Close()
	all, _ := ioutil.ReadAll(r.Body)
	// 获取响应内容的编码golang.org/x/net/html/charset
	encoding, _, _ := charset.DetermineEncoding(all, r.Header.Get("content-type"))
	//fmt.Println(encoding, name, certain)
	// 转换编码golang.org/x/text/transform
	reader := transform.NewReader(bytes.NewReader(all), encoding.NewDecoder())
	readAll, _ := ioutil.ReadAll(reader)
	fmt.Println(string(readAll))
}
```