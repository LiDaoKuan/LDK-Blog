---
title: GO语言反射
date: 2026-01-12
updated: 2026-01-13
tags: [GO, 反射]
categories: GO
---

### GO语言反射

所谓反射，即：允许程序在**运行时**检查和操作变量的类型和值。反射的核心是`reflect`包，它提供了丰富的API来处理变量的元信息。通过反射，可以动态获取变量的类型、值、结构体字段、方法等信息。

需要注意的是：反射会带来额外的性能开销，在需要高性能的使用场景下需要慎用。反射通常用于需要高度灵活性的场景，如：序列化、反序列化、ORM框架等。

在`GO`中，反射主要通过`reflect.Type`和`reflect.Value`来实现：

- `reflect.Type`：表示Go语言中的类型信息，可以通过`reflect.TypeOf()`来获取。
- `reflect.Value`：表示GO语言中的值信息，可以通过`reflect.ValueOf()`来获取。

使用示例：

简单使用：

```go
package main

import (
    "fmt"
    "reflect"
)

func main() {
    var x float64 = 3.14
    fmt.Println("Type:", reflect.TypeOf(x))
    fmt.Println("Value:", reflect.ValueOf(x))

    // 修改x的值, 必须通过 ValueOf(&x).Elem() 先传递指针再Elem的形式才能更改变量的值
    v := reflect.ValueOf(&x).Elem() // 获取x的指针并解引用
    v.SetFloat(2.71)               // 修改x的值
    fmt.Println("New value:", x)
}
```

复杂一点的例子

```go
package main

import (
	"fmt"
	"reflect"
)

type resume struct {
	Name string `info:"name" doc:"名字"`
	Sex  string `info:"sex"`
}

// 输出 struct 对象中的所有 tag
func findTag(str interface{}) {
	var t reflect.Type = reflect.TypeOf(str).Elem()
	var v reflect.Value = reflect.ValueOf(str).Elem()
	// 遍历所有字段
	for i := 0; i < t.NumField(); i++ {
		var fieldT reflect.StructField = t.Field(i)
		fmt.Println("fieldT: ", fieldT) // {Name  string info:"name" doc:"名字" 0 [0] false}
		var fieldV reflect.Value = v.Field(i)
		fmt.Println("fieldV: ", fieldV)                      // 张三
		fmt.Println("field Name: ", fieldT.Name)             // 当前字段变量名
		fmt.Println("field Type: ", fieldT.Type)             // 当前字段变量类型
		fmt.Println("field Tag: ", fieldT.Tag)               // 当前字段的 Tag
		fmt.Println("field Interface: ", fieldV.Interface()) // 张三
		tagInfo := fieldT.Tag.Get("info")                    // 获取当前字段的 info tag, 不存在则返回空串
		tagDoc := fieldT.Tag.Get("doc")                      // 获取当前字段的 doc tag, 不存在则返回空串
		fmt.Println("info: ", tagInfo, " doc: ", tagDoc)
		fmt.Println("----------------------------------------")
	}
}

func main() {
	// 对于 int 等基本类型
	var a = 100
	t1 := reflect.TypeOf(&a).Elem() // 传入&a, 再调用Elem() 等同于下面一行
	// t1 := reflect.TypeOf(a)
	fmt.Println("===============================")
	fmt.Println("Name: ", t1.Name())               // 输出 int
	fmt.Println("Kind: ", t1.Kind())               // 输出 int
	fmt.Println("t1: ", t1)                        // 输出 int
	fmt.Println("typeof t1: ", reflect.TypeOf(t1)) // 输出 *reflect.rtype
	fmt.Println("===============================")
	t2 := reflect.TypeOf(&a)                       // t2是指针类型, 因为传入的&a是指针
	fmt.Println("Name: ", t2.Name())               // 输出 空
	fmt.Println("Kind: ", t2.Kind())               // 输出 ptr
	fmt.Println("t2: ", t2)                        // 输出 *int
	fmt.Println("typeof t2: ", reflect.TypeOf(t2)) // 输出 *reflect.rtype
	fmt.Println("==============================")

	// 对于 struct
	var re resume = resume{"张三", "男"}
	typeRe1 := reflect.TypeOf(re)
	fmt.Println("===============================")
	fmt.Println("Name: ", typeRe1.Name())                    // 输出 resume
	fmt.Println("Kind: ", typeRe1.Kind())                    // 输出 struct
	fmt.Println("typeRe1: ", typeRe1)                        // 输出 main.resume
	fmt.Println("typeof typeRe1: ", reflect.TypeOf(typeRe1)) // 输出 *reflect.rtype
	fmt.Println("===============================")
	typeRe2 := reflect.TypeOf(&re)
	fmt.Println("Name: ", typeRe2.Name())                    // 输出 空
	fmt.Println("Kind: ", typeRe2.Kind())                    // 输出 ptr
	fmt.Println("typeRe2: ", typeRe2)                        // 输出 *main.resume
	fmt.Println("typeof typeRe2: ", reflect.TypeOf(typeRe2)) // 输出 *reflect.rtype
	fmt.Println("==============================")
	findTag(&re)

	// 设置 struct 变量的值, 必须通过先传入指针, 再Elem()才能设置变量的值
	v1 := reflect.ValueOf(&re).Elem()
	v1.Set(reflect.Zero(v1.Type()))
	fmt.Println(v1)
}

```

上述程序的输出：

```shell
===============================
Name:  int
Kind:  int
t1:  int
typeof t1:  *reflect.rtype
===============================
Name:  
Kind:  ptr
t2:  *int
typeof t2:  *reflect.rtype
==============================
===============================
Name:  resume
Kind:  struct
typeRe1:  main.resume
typeof typeRe1:  *reflect.rtype
===============================
Name:  
Kind:  ptr
typeRe2:  *main.resume
typeof typeRe2:  *reflect.rtype
==============================
fieldT:  {Name  string info:"name" doc:"名字" 0 [0] false}
fieldV:  张三
field Name:  Name
field Type:  string
field Tag:  info:"name" doc:"名字"
field Interface:  张三
info:  name  doc:  名字
----------------------------------------
fieldT:  {Sex  string info:"sex" 16 [1] false}
fieldV:  男
field Name:  Sex
field Type:  string
field Tag:  info:"sex"
field Interface:  男
info:  sex  doc:  
----------------------------------------
{ }
```

#### 调用结构体方法

```go
package main

import (
    "fmt"
    "reflect"
)

type Person struct {
    Name string
    Age  int
}

func (p Person) SayHello() {
    fmt.Printf("Hello, my name is %s and I am %d years old.\n", p.Name, p.Age)
}

func main() {
    p := Person{Name: "Bob", Age: 25}
    v := reflect.ValueOf(p)
    method := v.MethodByName("SayHello")
    method.Call(nil)
}
```

