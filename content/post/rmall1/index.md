---
title: "从0实现基于gin的rmall商城项目（一）配置文件"
description: ""
date: 2023-11-22
math: 
license: 
hidden: false
comments: true
image: golang_6.jpeg
draft: false
categories: ["编程","gin","golang"]
tags: ["rmall","商城"]
---

学习golang已经有一段时间了，一直是跟着别人的代码一个一个敲，目前有一点自己的项目理解，所以决定自己使用go来完成一个商城项目，本教程以一个小白的角度搭建，清晰易懂

## 框架的选择

本项目使用 **gin** + **sqlx** + **viper** + **casbin**

- 数据库：**MySQL**

- 缓存：**Redis**

- 接口文档：**swagger**

开发环境：**go1.20** 、**MySQL8.0** 、（redis暂时还没用上）

项目地址:[https://github.com/rice408s/rmall](https://github.com/rice408s/rmall)

## 项目结构

```
├── api         // 接口
├── config      // 配置文件
├── docs        // swagger文档
├── dao			//数据操作层
├── global      // 全局变量
├── initialize  // 初始化
├── model   	// 数据库模型
├── router  	// 路由
├── service 	// 服务
├── utils   	// 工具
├── sql			// 存放sql文件
├── test		// 存放测试文件
├── config.yaml // 配置文件
├── log.log		// 日志文件
├── main.go     // 入口
├── README.md   // 说明文档
├── go.mod		// go包管理工具
```

  ## 项目初始化

创建初始化项目

```sh
mkdir rmall && cd rmall && go mod init rmall
```

按照项目结构依次创建文件



## 基础配置

我们在 `config` 目录下创建 `config.go` 文件，写入如下配置

```go
package config

type Config struct {
	Mysql Mysql `mapstructure:"mysql" json:"mysql" yaml:"mysql"`
}

// Mysql  MySQL配置
type Mysql struct {
	Host     string `mapstructure:"host" json:"host" yaml:"host"`             // 主机名
	Port     int    `mapstructure:"port" json:"port" yaml:"port"`             // 端口号
	Username string `mapstructure:"username" json:"username" yaml:"username"` // 用户名
	Password string `mapstructure:"password" json:"password" yaml:"password"` // 密码
	Dbname   string `mapstructure:"dbname" json:"dbname" yaml:"dbname"`       // 数据库名
	Params   string `mapstructure:"params" json:"params" yaml:"params"`       // 链接参数
}
```

然后在 `global`  下创建 `global.go` 文件，写入下列代码

```go
package global

import (
	"rmall/config"
)

// 定义全局变量
var (
	Config config.Config
)

```

通过全局变量，我们就可以轻松的访问配置文件中的数据了

## 编写配置文件

这里的配置文件使用的是 `yaml` 文件，我们在项目的根目录下创建 `config.yaml`，写入如下配置

```yaml
mysql:
  host: "127.0.0.1"
  port: "3306"
  username: "root"
  password: "123456"
  dbname: "rmall"
  params: "charset=utf8mb4&parseTime=True"
```

这里的配置文件的值根据自己的实际情况去书写

## 载入配置文件

这里使用的go的viper包来加载配置文件，获取viper包

```sh
go get github.com/spf13/viper
```

在 `initialize` 目录下创建 `config.go` ，写入

```go
package initialize

import (
	"fmt"
	"github.com/spf13/viper"
	"rmall/global"
)

func LoadConfig(path string) {
	viper.SetConfigFile(path)
	viper.SetConfigName("config") //文件名为config
	viper.SetConfigType("yaml")	  //文件后缀为yaml
	//添加配置文件所在的路径，注意在Linux环境下%GOPATH要替换为$GOPATH
	viper.AddConfigPath(".")	  //配置文件路径
	if err := viper.ReadInConfig(); err != nil {
		fmt.Println("viper.ReadInConfig failed,err:", err)
		return
	}
	err := viper.Unmarshal(&global.Config) //将读取到的配置解析到创建的全局变量上
	if err != nil {
		fmt.Println("viper.Unmarshal failed,err:", err)
		return
	}
}

```

再在 `initialize` 目录下创建 `run.go`，写入下列代码

```go
package initialize
func Run() {
	LoadConfig("./config.yaml") //配置文件的路径
}
 
```

再在 ` main.go` 中添加下列代码

```go
package main

import (
	"rmall/initialize"
)

func main() {
	initialize.Run()
}
```

这样配置文件就配置完成了，之后的函数调用都可以写在 `Run()` 方法中，这样 `main()` 只需要调用 `Run()` 就行了，保持简洁

