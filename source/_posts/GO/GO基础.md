---
title: GO基础语法
date: 2026-01-05
updated: 2025-01-05
tags: [GO, 语法]
categories: GO
description: GO语言基础
---

本篇主要用于记录GO的基础语法, 如果哪一天我生疏了可以通过这篇文章快速回忆

### 基础语法

```go
package main

import (
	"fmt"
	"strconv"
	"time"
)

// 变量
func testVar() {
	// 变量声明: 不给初始值, int 类型 默认初始值为0
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
	fmt.Printf("num_2 = %f, type is num_2: %T\n", num2, num2) // %T是类型占位符

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

// 多返回值, 返回值带变量名. 此时对应的变量实际上属于局部变量
func testReturnWithName(a int, b int) (sum int, mul int) {
	// sum 和 mul 本质上是局部变量
	fmt.Println("before assign, sum= ", sum, " mul= ", mul) // 没有赋值前, 默认为0
	sum = a + b
	mul = a * b
	return
	// 也可以不用变量名, 直接用return返回结果, 此时 对变量的赋值将会失效, 以return返回的值为准:
	// return 100, 200 // 将会使 sum 和 mul 的值失效
}

// 多返回值, 带变量名, 返回值存在同类型
func testReturnWithNameAndSameType(a int, b int) (sum, mul int, sumStr string) {
	sum = a + b
	mul = a * b
	sumStr = strconv.Itoa(sum)
	return
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
	var sum1, mul1 int = testMultipleReturn(a, b)
	fmt.Println("sum1 = ", sum1, " mul1 = ", mul1)
	sum1, mul1 = testReturnWithName(a, b)
	fmt.Println("sum1 = ", sum1, "mul1 = ", mul1)
	sum1, mul1, sumStr := testReturnWithNameAndSameType(a, b)
	fmt.Println("sum1 = ", sum1, "mul1 = ", mul1, "sum_str = ", sumStr)
}
```

### import导包顺序和init函数

在`go语言`中，`package（包）`实际上就是一个文件夹，这个文件夹内可以有很多个`.go`文件，每个`.go`文件都可以写`init()`函数，如果不写，`go`自己会提供一个默认的`init()`函数。`import "test"`时，会**依次**执行文件夹`test`中的所有`.go`文件中的`init()`函数（此处的依次执行，具体先后顺序暂无定论），当然，如果`test`文件夹中的`.go`文件还引入了其他`package`，则会优先递归执行其他`package`中的初始化操作。具体顺序见下图：

![import顺序](https://image-1258881983.cos.ap-beijing.myqcloud.com/hVMYyqi6EU.png)

1. 如果一个包导入了其他包，则首先初始化导入的包。
2. 然后初始化当前包的常量。
3. 接下来初始化当前包的变量。
4. 最后，调用当前包的 `init()` 函数。

> 如果两个`.go`文件属于同一个文件夹，那也意味着他们属于同一个包。
> 此时不需要`import`操作，他们也可以相互访问公共接口函数（**以大写字母开头的函数**）。

测试代码：

```go
// lib1/lib1.go
package lib1

import "fmt"
import "GoTest/lib2"

func init() {
	fmt.Println("lib1 init() called")
}

// 如果要在其他包中使用该函数, 那么函数名必须以大写字母开头
func Test() {
	fmt.Println("lib1 Test() called")
	lib2.Test()
}
```

```go
// lib2/lib2.go
package lib2

import (
	"fmt"
)

func init() {
	fmt.Println("lib2 init() called")
}

func Test() {
	fmt.Println("lib2 Test() called")
}

```

```go
// main.go

package main

// 默认从 $GOROOT 或者 $GOPATH 找package, 因此此处必须是相对于 $GOROOT 或者 $GOPATH 的路径
// 如果配置了 go module 则另当别论
import "GoTest/lib1"
import "GoTest/lib2"

func main() {
	lib1.Test()
	lib2.Test()
}

func init() {
	fmt.Println("main.go init() called")
}
```

### import匿名导包和别名导包

```go
package main

import (
	_ "GoTest/lib1"      // 匿名别名导包. 不能使用包内的函数, 但是会自动调用 init 函数
	mylib2 "GoTest/lib2" // 别名导包. 起了别名之后原名就不能使用了
    // . "GoTest/lib1" // 缺省导包, 可以直接使用lib1中的接口函数而不需要在前面指明lib1
    // 例如: Test() 而不是 lib1.Test()
    // 如果存在多个包使用缺省方式导入, 那么他们之间不能存在同名的接口函数, 否则会报错: 重定义
    // 缺省导包后, 原包名同样不能使用.
    // 缺省导包依旧会调用包中的init()函数
	"fmt"
)

func main() {
	// lib1.Test()
	mylib2.Test()
}

func init() {
	fmt.Println("main.go init() called")
}

```

### 指针与引用

和`C/C++`差不多，只不过是反着写的。

```go
package main

import "fmt"

func changeValue(p *int) {
	*p = 100
	fmt.Println("address of a = ", p)
}

func main() {
	var a int = 10
	changeValue(&a)
	fmt.Println("a = ", a)

	var p *int = &a
	fmt.Println("A point point to a = ", p)
	var pp **int = &p // 二级指针
	fmt.Println("A point point to p = ", pp)
}
```

### defer语句

```go
package main

import "fmt"

func deferCall() {
	fmt.Println("deferCall() called")
}

func returnCall() int {
	fmt.Println("returnCall() called")
	return 1
}

func test() int {
	defer fmt.Println("first defer")  // 先入栈, 后执行
	defer fmt.Println("second defer") // 后入栈, 先执行
	defer deferCall()                 // defer 后面也可以跟函数
	return returnCall()               // return 语句比 defer 语句先执行
}

func main() {

	test()

	fmt.Println("main() called")
}
```

上述代码的输出：

```shell
returnCall() called
deferCall() called
second defer
first defer
main() called
```

### 数组

#### 定长数组

```go
package main

import "fmt"

// 用定长数组作为函数参数, 必须指明数组长度, 并且是深拷贝（拷贝了一整个数组）
// 因此一般不这么用, 如果要传递数组, 应该考虑动态数组
func printArrayLen_10(arr [10]int) {
    for i := 0; i < len(arr); i++ {
       fmt.Print(arr[i], " ")
    }
    fmt.Println()
}

func main() {
    // 固定长度的数组
    var array1 [10]int
    array2 := [10]int{10, 20, 30, 40} // 前4个元素给初始化值, 后面的元素默认值都为0

    printArrayLen_10(array1)

    // 另一种 for 循环遍历方法, index表示当前元素的下标, value表示当前元素的值
    for index, value := range array2 {
       fmt.Println("index = ", index, "value = ", value)
    }

    // 查看数组的数据类型:
    fmt.Printf("array1 types is %T\n", array1)
    fmt.Printf("array2 types is %T\n", array2)
}
```

#### 动态数组（切片 slice）

##### 基本使用

```go
package main

import "fmt"

// 动态数组传参是浅拷贝, 内部更改外部也会生效
// 浅拷贝的根本原因:
//   - GO语言中, 切片slice是引用类型, 管理底层数组, 多个切片可以共享同一个底层数组.
//   - 可以理解为在GO语言中, 默认一个切片赋值给其他切片时, 类似于C++中, 复制一个对象内部管理的指针给另一个对象
//   - 而在GO语言中, 如果要实现切片的复制操作(深拷贝), 需要调用make和copy两个函数
//
// 复制切片案例:
// src := []int{1, 2, 3}
// dst := make([]int, len(src))
// copy(dst, src)
// 
// 单纯执行 dst := src 只不过是让dst也指向src管理的内部数组而已, 实际上两者还是同一个数组
func changeValue(arr []int) {
	if len(arr) > 0 {
		arr[0] = 100
	}
}

func printArray(arr []int) {
	// _ 表示匿名, 即不关心下标
	for _, v := range arr {
		fmt.Print(v, " ")
	}
	fmt.Println()
}

func main() {
	array1 := []int{10, 20, 30, 40} // 动态数组, 初始化为4个元素. 也叫 切片 slice
	changeValue(array1)
	printArray(array1)
}
```

##### 切片的4种定义方式

```go
package main

import "fmt"

func main() {
	// 1. 声明并初始化
	arr1 := []int{10, 20, 30, 40}
	fmt.Println(arr1)

	// 2. 声明, 但不初始化. 为空, 同样也就无法使用
	var arr2 []int
	fmt.Println(arr2)      // 为空
	arr2 = make([]int, 10) // 分配空间
	fmt.Println("arr2: ", arr2)

	// 3. 声明, 同时分配空间
	var arr3 []int = make([]int, 10)
	fmt.Println("arr3: ", arr3)

	// 4. 直接make, 通过 := 推导出类型
	arr4 := make([]int, 10)
	fmt.Println("arr4: ", arr4)
}
```

##### 判断slice是否为空

在go中，空值用`nil`表示

```go
package main

import "fmt"

func main() {
	arr1 := []int{}        // 此种方式不为空, 长度为0但是有分配空间
	arr2 := make([]int, 0) // 不为空
	var arr3 []int         // 为空, 根本没有分配空间
	if arr1 == nil {
		fmt.Println("arr1 is nil")
	}
	if arr2 == nil {
		fmt.Println("arr2 is nil")
	}
	if arr3 == nil {
		fmt.Println("arr3 is nil")
	}
	fmt.Println(arr1)
	fmt.Println(arr2)
	fmt.Println(arr3)
}

```

##### 切片的追加

```go
package main

import "fmt"

func main() {
	// 定义一个切片, 长度为3, 容量为5
	arr := make([]int, 3, 5)
	// 打印长度和容量
	fmt.Printf("arr = %v, len = %d, cap = %d\n", arr, len(arr), cap(arr))
	// 此时直接访问长度外的元素会出错
	// arr[4] = 100

	// 尾插. 必须接受该函数的返回值
	arr = append(arr, 10)
	arr = append(arr, 10)
	arr = append(arr, 10)
	// 超过了容量5, 进行了扩容（与C++ vector扩容机制类似，都需要进行数据复制）
	fmt.Printf("arr = %v, len = %d, cap = %d\n", arr, len(arr), cap(arr))
}

```

##### 切片的截取

```go
package main

import "fmt"

func main() {
	arr := []int{0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
	arrSlip := arr[:5] // 等同于 arrSlip := arr[0:3], 左闭右开区间
	fmt.Println(arrSlip)
	arrSlip[0] = 100 // 此种方式获得的新切片依旧指向与原切片相同的底层数组
	fmt.Println(arr) // arr 中的元素也被更改
	
	copy(arrSlip, arr[1:2]) // 如果要拷贝, 可以使用这种方法. 但是目标数组（第一个参数）必须已经分配空间
	// copy在将大数组拷贝到小数组时, 会发生截断情况
	// copy在将小数组拷贝到大数组时, 会只更改大数组中与小数组长度相同的那部分, 后面的部分会保留原始值不变
	fmt.Println(arrSlip)
}
```

### map
