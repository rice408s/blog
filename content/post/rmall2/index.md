---
title: "从0实现基于gin的rmall商城项目（二）数据库操作"
description: ""
date: 2023-11-25
math: 
license: 
hidden: false
comments: true
image: golang_7.jpeg
draft: false
categories: ["编程","gin","golang"]
tags: ["rmall","商城"]
---

上一期已经实现了配置文件的读取，这一期来实现数据库的配置

## 数据库配置

这里使用的是 `MySQL` 数据库，orm框架使用的是 `sqlx`,执行下列命令获取 `sqlx` 和 `mysql` 驱动

```shell
go get github.com/jmoiron/sqlx 
go get github.com/go-sql-driver/mysql
```

在 `initialize` 包下创建 `db.go`,写入下列代码

```go
package initialize

import (
	"fmt"
	_ "github.com/go-sql-driver/mysql" //只导入依赖，mysql驱动
	"github.com/jmoiron/sqlx"
	"rmall/global"
)

func Mysql() {
	//拼接dsn
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?%s",
		global.Config.Mysql.Username,
		global.Config.Mysql.Password,
		global.Config.Mysql.Host,
		global.Config.Mysql.Port,
		global.Config.Mysql.Dbname,
		global.Config.Mysql.Params,
	)
    //dsn=root:123456@tcp(127.0.0.1:3306)/rmall?charset=utf8mb4&parseTime=True
	var err error
	global.Db, err = sqlx.Connect("mysql", dsn)
	if err != nil {
		fmt.Println("sqlx.Connect failed,err:", err)
		return
	}
	// 最大空闲连接数
	global.Db.SetMaxIdleConns(20)
	// 最大打开连接数
	global.Db.SetMaxOpenConns(20)
}

```

再在`run.go`中调用

```go
package initialize

func Run() {
	LoadConfig("./config.yaml")
	Mysql()
}
```



通过这里已经连接好 `Mysql` 了，现在通过global.Db就可以对数据库进行操作了

接下来先创建用户表,在 `sql` 目录下创建 `user.sql` 写入下列内容

```sql
CREATE TABLE User
(
    id        INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    username  VARCHAR(50) comment '用户名',
    password  VARCHAR(100) comment '密码',
    mobile    VARCHAR(20) comment '手机号',
    email     VARCHAR(50) comment '邮箱',
    created_at TIMESTAMP comment '创建时间',
    updated_at TIMESTAMP comment '更新时间',
    deleted_at TIMESTAMP comment '删除时间'
);
```

执行这个sql就可以创建用户表了,接下来就对用户表进行操作,在 `dao` 目录下创建 `user.go`,实现下列三个函数

```go
package dao

import (
	"rmall/global"
	"rmall/model"
)

// AddUser 添加用户
func AddUser(user *model.User) (id int, err error) {
	insertStr := `insert into user(username,password,mobile,email,created_at) values(?,?,?,?,?)` 	// 插入语句
	res, err := global.Db.Exec(insertStr, user.Username, user.Password, user.Mobile, user.Email, user.CreatedAt) //执行插入语句
	if err != nil {
		return 0, err
	}
	insertId, err := res.LastInsertId()
	return int(insertId), err //返回插入成功的id

}

// FindUserByUsername 根据用户名查找用户
func FindUserByUsername(username string) (user *model.User, err error) {
	queryStr := `select * from user where username=?`
	user = &model.User{}
	err = global.Db.Get(user, queryStr, username)
	if err != nil {
		return nil, err
	}
	return user, nil
}

// FindUserById 根据用户id查找用户
func FindUserById(Id int) (user *model.User, err error) {
	queryStr := `select * from user where id=?`
	user = &model.User{}
	err = global.Db.Get(user, queryStr, Id)
	if err != nil {
		return nil, err
	}
	return user, nil

}
```

通过这三个函数就可添加用户,通过用户名查询用户,通过用户id查询用户了,我们需要将这几个函数封装到   `service` 中,在 `service` 下创建 `user.go` ,写入下列代码

```go
package service

import (
	"database/sql"
	"errors"
	"fmt"
	"rmall/dao"
	"rmall/model"
	"rmall/model/request"
	"rmall/utils"
	"time"
)

// Register 用户注册
func Register(req *request.RegisterReq) (int, error) {
	fmt.Println("hello")
	// 参数校验
	if req.Username == "" || req.Password == "" || req.Mobile == "" || req.Email == "" {
		return 0, errors.New("参数错误")
	}
	fmt.Println("hello")
	//检测用户名是否存在
	user, err := dao.FindUserByUsername(req.Username)
	if err != nil && !errors.Is(err, sql.ErrNoRows) {
		fmt.Println(err)
		return 0, err
	}

	if user != nil {
		return 0, errors.New("用户名已存在")
	}
	// 密码加密
	hashPwd, err := utils.HashPassword(req.Password)
	if err != nil {
		return 0, err
	}
	// 保存用户信息
	user = &model.User{
		Username:  req.Username,
		Password:  hashPwd,
		Mobile:    req.Mobile,
		Email:     req.Email,
		CreatedAt: time.Now(),
	}

	//插入数据库
	return dao.AddUser(user)

}

func Login(req *request.LoginReq) (string, int64, error) {
	// 参数校验
	if req.Username == "" || req.Password == "" {
		return "", 0, errors.New("参数错误")
	}
	//检测用户名是否存在
	user, err := dao.FindUserByUsername(req.Username)
	if errors.Is(err, sql.ErrNoRows) {
		return "", 0, err
	}
	// 检测密码是否正确
	if !utils.CheckPasswordHash(req.Password, user.Password) {
		return "", 0, errors.New("密码错误")
	}

	token, expire, err := utils.CreateToken(user)
	if err != nil {
		return "", 0, err
	}
	return token, expire, nil

}

func FindUserById(Id int) (user *model.User, err error) {
	return dao.FindUserById(Id)
}

// FindUserByUsername 通过用户名查询用户信息
func FindUserByUsername(username string) (user *model.User, err error) {
	return dao.FindUserByUsername(username)
}

```

因为我们不会在 `service` 层直接写sql,而写 `api` 层是与 `service` 层交互,所以我们在这里实现了 ` FindUserById(Id int)` 和 `FindUserByUsername(username string)`,然后实现登录和注册函数,在这两个函数中,我们使用了加密函数 `utils.HashPassword()` 和 `utils.CheckPasswordHash()`,因为在数据库中我们不会明文存储密码,如果数据库被攻击,那么所有人的密码都会泄露,这是很不安全的,所以我们要对密码进行加密,在 `utils` 下创建 `crypt.go` 实现下列函数

```go
package utils

import "golang.org/x/crypto/bcrypt"

// HashPassword 密码加密
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPasswordHash 密码验证
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
```

 这里使用的是go的 `bcrypt` 包对密码进行加密和验证,在注册和登陆函数中,我们还使用了 `*request.RegisterReq` 和 `*request.LoginReq`,因为不推荐直接使用 `User` 这个model进行数据传输 ,所以我们在 `model` 下创建 `request` 和 `response` 目录,用来存放请求体和响应体,分别在两个目录下创建 `user.go`,写入

```go
package request

// LoginReq 登陆请求
type LoginReq struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// RegisterReq 注册请求
type RegisterReq struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
	Mobile   string `json:"mobile" binding:"required"`
	Email    string `json:"email" binding:"required"`
}
```



```go
package response

type LoginResp struct {
	Token string `json:"token"`
	// 过期时间
	Expire int64 `json:"expire"`
}

type RegisterResp struct {
	Id       int    `json:"id"`
	Username string `json:"username"`
	Mobile   string `json:"mobile"`
	Email    string `json:"email"`
}

type UserInfo struct {
	Id       int    `json:"id"`
	Username string `json:"username"`
	Mobile   string `json:"mobile"`
	Email    string `json:"email"`
}
```

到这里基本都数据库操作就完成了,有些方法还没有实现,后续慢慢添加