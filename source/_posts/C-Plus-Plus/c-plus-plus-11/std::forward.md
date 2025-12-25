---
title: 完美转发(std::forward)
tags: [Cpp, 移动语义, 完美转发]
categories: Cpp
date: 2025-07-06
---

### 左值和右值

了解完美转发前，必须先了解左值和右值的概念，以及左值引用和右值引用的概念。参见：[左值/右值引用和std::move](https://ldkblog.top/undefined/C-Plus-Plus/c-plus-plus-11/std::move/)

### 万能引用

万能引用是一种特殊的引用，它**只能出现在模板函数和模板类**中。并且，万能引用的格式固定，为`T&& t`，其中变量`t`就是万能引用，而`T`就是模板参数。例如下面的的代码：

```cpp
template <typename T>
void func(T &&t) {
    // t就是万能引用
}
```

### 引用折叠

上面说了万能引用的格式，那为什么万能引用是万能的？这就是引用折叠的用处了。

已知万能引用的模板参数`T`是可以推导为具体类型的，也就是说：`T`可以是`string`，也可以是`string&`，也可以是`string&&`等等。那么，展开后，`T&& t`不久变成了：`string&& && t`，这么多`&`，这是什么玩意儿？C++11立了规矩，太多`&`要折叠一下，于是便产生了引用折叠。

引用折叠的具体规则：

- `Type& &`，`Type&& &`，`Type& &&`都折叠成`Type&`.
- `Type&& &&`折叠成`Type&&`.

那要怎么判断模板参数`T`最后被推断为什么类型呢？看下面代码：

```cpp
#include <iostream>
#include <type_traits>
#include <string>
using namespace std;

template <typename T>
void func(T &&param)
{
    if (std::is_same<string, T>::value)
    {
        std::cout << "string" << std::endl;
    }
    else if (std::is_same<string &, T>::value)
    {
        std::cout << "string&" << std::endl;
    }
    else if (std::is_same<string &&, T>::value)
    {
        std::cout << "string&&" << std::endl;
    }
    else if (std::is_same<int, T>::value)
    {
        std::cout << "int" << std::endl;
    }
    else if (std::is_same<int &, T>::value)
    {
        std::cout << "int&" << std::endl;
    }
    else if (std::is_same<int &&, T>::value)
    {
        std::cout << "int&&" << std::endl;
    }
    else
    {
        std::cout << "unkown" << std::endl;
    }
}

int getInt() {
    return 10;
}

int main() {
    int x = 1;
    func(1); // 传递参数是右值 T推导成了int, 所以是int&& param, 右值引用
    func(x); // 传递参数是左值 T推导成了int&, 所以是int& && param, 折叠成 int&,左值引用
    func(getInt()); // 参数getInt是右值 T推导成了int, 所以是int&& param, 右值引用

    return 0;
}
```

上述代码输出：
```shell
int
int&
int
int&
```

### std::forward

实现完美转发的关键是`std::forward`，其定义如下：

```cpp
// 接收左值的版本
template <typename _Tp>
[[__nodiscard__, __gnu__::__always_inline__]] constexpr _Tp &&forward(typename std::remove_reference<_Tp>::type &__t) noexcept {
    return static_cast<_Tp &&>(__t);
}

// 接收右值的版本
template <typename _Tp>
[[__nodiscard__, __gnu__::__always_inline__]] constexpr _Tp &&forward(typename std::remove_reference<_Tp>::type &&__t) noexcept {
    static_assert(!std::is_lvalue_reference<_Tp>::value, "template argument" " substituting _Tp is an lvalue reference type");
    return static_cast<_Tp &&>(__t);
}
```

先看形参：

- 第一个函数的形参类型是`typename std::remove_reference<_Tp>::type &__t`，前面`std::remove_reference<_Tp>::type`不理解，先不管。主要看后面`& __t`，这说明`__t`肯定是一个左值引用，左值引用当然要接收左值。类似于`int& b = a`，`b`就是一个左值引用，接收左值`a`。
- 第二个函数的形参也类似，`__t`肯定是一个右值引用，右值引用当然要接收右值。

再看返回值：

两个函数的返回值都是`static_cast<_Tp &&>(__t);`，很显然，这是将`__t`的类型转换为`_Tp &&`。但`_Tp &&`到底是什么类型？这就要看`_Tp`的类型了。而`_Tp`又是我们在调用`std::forward`时指定的。以`int`为例：

```cpp
std::forward<int>(100); // 调用右值版本, 同时_Tp指定为int, 则返回值为static_cast<int &&>(__t), 为右值引用类型。
std::forward<int&>(100); // 调用右值版本, 同时_Tp指定为int&, 则返回值为static_cast<int& &&>(__t), 引用折叠后为static_cast<int&>(__t), 为左值引用类型。

int x = 100
std::forward<int&&>(x); // 调用左值版本, 同时_Tp指定为int&&, 则返回值为static_cast<int&& &&>(__t), 引用折叠后为static_cast<int&&>(__t), 为右值引用类型。
```

下面是测试代码：
```cpp
#include <iostream>
#include <type_traits>
#include <string>
#include <memory>
using namespace std;

// 用于解析模板参数T的类型名称
// 跨平台的类型名称获取函数, 能正确显示引用
template <typename T>
std::string type_name() {
#if defined(__clang__)
    std::string pretty_function = __PRETTY_FUNCTION__;
    size_t start = pretty_function.find("T = ") + 4;
    size_t end = pretty_function.find("]", start);
    return pretty_function.substr(start, end - start);

#elif defined(__GNUC__)
    std::string pretty_function = __PRETTY_FUNCTION__;
    size_t start = pretty_function.find("T = ") + 4;
    size_t end = pretty_function.find(";", start);
    return pretty_function.substr(start, end - start);

#elif defined(_MSC_VER)
    std::string pretty_function = __FUNCSIG__;
    size_t start = pretty_function.find("type_name<") + 10;
    size_t end = pretty_function.find(">(void)");
    return pretty_function.substr(start, end - start);

#else
#error "Unsupported compiler"
#endif
}

// 专用于判断std::forward返回的是左值引用还是右值引用的函数
template <typename T>
void verify_forward_type(const char *description) {
    if constexpr (std::is_lvalue_reference_v<T>) {
        std::cout << description << " is an lvalue reference ("
                  << (std::is_const_v<std::remove_reference_t<T>> ? "const " : "")
                  << "T&)" << std::endl;
    } else if constexpr (std::is_rvalue_reference_v<T>) {
        std::cout << description << " is an rvalue reference ("
                  << (std::is_const_v<std::remove_reference_t<T>> ? "const " : "")
                  << "T&&)" << std::endl;
    } else {
        std::cout << description << " is not a reference (T)" << std::endl;
    }
}

// 随便写一个强制返回右值引用的函数, 进行测试
int &&getInt() {
    return std::move(10);
}

int main() {
    int x = 10;

    // 调用右值版本(第二个函数), 指定_Tp为int, 那么返回值为 static_cast<int &&>(__t), 为右值引用
    std::cout << type_name<decltype(std::forward<int>(100))>() << std::endl;

    // 调用左值版本(第一个函数), 指定_Tp为int&, 那么返回值为 static_cast<int& &&>(__t),
    // 引用折叠后为static_cast<int&>(__t), 为左值引用
    std::cout << type_name<decltype(std::forward<int &>(x))>() << std::endl;

    // 调用左值版本(第一个函数), 指定_Tp为int&&, 那么返回值为 static_cast<int&& &&>(__t),
    // 引用折叠后为static_cast<int&&>(__t), 为右值引用
    std::cout << type_name<decltype(std::forward<int &&>(x))>() << std::endl;

    // 调用右值版本(第二个函数), 指定_Tp为const int&&, 那么返回值为 static_cast<const int&& &&>(__t),
    // 引用折叠后为static_cast<const int&&>(__t) 为右值引用
    std::cout << type_name<decltype(std::forward<const int &&>(100))>() << std::endl;

    // 输出int&&
    std::cout << type_name<decltype(getInt())>() << std::endl;

    // const int&& 是右值引用
    verify_forward_type<decltype(std::forward<const int &&>(x))>("std::forward<const int&&>(x)");

    return 0;
}

```

代码输出：
```shell
int&&
int&
int&&
const int&&
int&&
std::forward<const int&&>(x) is an rvalue reference (const T&&)
```

### 完美转发

先看一段程序：
```cpp
template<typename T>
void print(T & t){
    std::cout << "Lvalue ref" << std::endl;
}

template<typename T>
void print(T && t){
    std::cout << "Rvalue ref" << std::endl;
}

template<typename T>
void testForward(T && v){ 
    print(v);//v此时已经是个左值了,永远调用左值版本的print
    print(std::forward<T>(v)); //本文的重点
    print(std::move(v)); //永远调用右值版本的print

    std::cout << "======================" << std::endl;
}

int main(int argc, char * argv[])
{
    int x = 1;
    testForward(x); //实参为左值
    testForward(std::move(x)); //实参为右值
}
```

这段程序的输出如下：
```shell
Lvalue ref
Lvalue ref
Rvalue ref
======================
Lvalue ref
Rvalue ref
Rvalue ref
======================
```

对比前后两次输出，第一行和第三行都是一样的。只有第二行不一样。为什么？

因为在函数`void testForward(T && v)`中，无论调用`testForward()`时传入的是左值还是右值，也即：无论`T&& v`是左值引用还是右值引用，`v`都必定是右值。(左值引用和右值引用都属于左值)，这在[std::move](https://ldkblog.top/undefined/C-Plus-Plus/c-plus-plus-11/std::move/)中介绍过。

所以`print(v)`一定调用左值版本（因为`v`是左值），`print(std::move(v))`一定调用右值版本（因为`std::move()`返回右值）。

而`std::forward<T>(v)`不一样，它根据调用时传入的模板参数`T`的类型，决定最后的返回类型到底是左值引用还是右值引用，又因为左值引用一定是左值，而右值引用在作为返回值时是右值，所以也间接决定了返回类型到底属于左值还是右值。也就是说：**通过模板参数T控制返回值是左值还是右值**。

### 完美转发的应用场景

暂时不讨论。网上说的比较多的是工厂函数和包装器。但是个人用到的并不多。后面用到再补充。