---
title: C++语法
date: 2026-01-05
updated: 2025-01-05
tags: [GO, 语法]
categories: GO
description: GO基础
---

本篇主要用于记录GO的基础语法, 如果哪一天我生疏了可以通过这篇文章快速回忆

### day001

```GO
package main

import "fmt" // 格式化包
import "time"

// 变量
func testVar() {
	// 变量声明: 补给初始值
	var num0 int
	fmt.Println(num0) // 默认为0

	// 声明的同时给初始值, 可以省略类型:
	var numString = "123456" // 省略了类型 string
	// 等同于: var num_string string = "123456"
	fmt.Println("num_1: ", numString)
	// 上面一行等同于 fmt.Println("num_1: " + num_string)

	var num1 int = 12
	fmt.Printf("type of num_1: %T\n", num1) // 通过Printf和占位符 %T 判断变量类型

	// 最常用的变量定义方法:
	num2 := 3.14 // 只能在函数体内使用这种方式, 在全局位置（所有函数体的外面）使用这种声明会报错
	fmt.Printf("num_2 = %f, type is num_2: %T\n", num2, num2)

	// 声明多个同类型的变量
	var xx, yy = 1, 2
	fmt.Printf("xx = %d, yy = %d\n", xx, yy)
	// 声明多个不同类型的变量
	var kk, ll = 100, "str" // 此处的 var 不能省略
	fmt.Printf("kk = %d, ll = %s\n", kk, ll)

	// 多行多变量声明
	var (
		var1 int     = 100 // 此处类型也可省略！
		var2 bool    = true
		var3 float32 = 3.14
	)
	fmt.Println("var1 =", var1, "var2 =", var2, "var3 =", var3)
}

// const 关键字
func testConst() {
	// 将 var 替换为 const, 即可定义常量.
	const length int = 10 // 类型依旧可以省略
	fmt.Println(length)

	const (
		BEIJING = iota // 定义 BEIJING 的值为0, 后面每一行累加1
		SHANGHAI
		SHENZHEN
		GUANGZHOU
	)
	// iota 只能出现在 const 块中

	const (
		NUM_1 = iota * 10 // iota 从0开始地层
		NUM_2             // 10 因为 iota 是每次+1, 所以变量每次 + 10
		NUM_3             // 20
		NUM_4             // 30
	)

	const (
		a, b = iota + 1, iota + 2 // iota=0, a=iota+1, b=iota+2
		c, d                      // iota=1, c=iota+1, b=iota+2
		e, f
		g, h = iota * 2, iota * 3 // iota=3, g=iota*2, h=iota*3
		i, k                      // iota=4, i=iota*2, k=iota*3
	)
}

// 多返回值
func testMultipleReturn(a int, b int) (int, int) {
	return a + b, a * b
}

func main() { // 函数的左括号一定和函数名在同一行, 否则编译错误
	fmt.Println("test go") // 每一句结尾可以不加 ';'
	fmt.Println("wait for 1 second")
	time.Sleep(time.Second * 1)
	fmt.Println("1 second wait finished")

	testVar()
	testConst()

	var a = 10
	var b = 20
	var ret1, ret2 int = testMultipleReturn(a, b)
	fmt.Println("ret1 = ", ret1, " ret2 = ", ret2)
}

```
