---
title: std::function详解
tags: [Cpp]
categories: Cpp
date: 2025-10-06
---

## 基本概念

`std::function` 是一种通用的、多态的 **函数封装器**，可以存储、复制和调用任何**可调用对象**（如函数、函数指针、成员函数指针、`lambda`表达式等）。其基本语法如下：

```cpp
int foo(int a, std::string s){
    std::cout << a << ' ' << s << "\n";
}

std::function<int(int, std::string)> func = foo;
func(100, "test string"); // 输出：100 test string
```

## 使用

上面已经说明了基础语法，这里列举不同的使用情况：

- 函数指针

  ```cpp
  int foo(int a, std::string s){
      std::cout << a << ' ' << s << "\n";
  }
  std::function<int(int, std::string)> func = foo;
  func(100, "test string"); // 输出：100 test string
  
  // 特殊情况：如果包装的函数没有形参，则可以不写std::function的模板参数
  int foo() {
      std::cout << "test func" << std::endl;
      return 100;
  }
  std::function func = foo;
  func(); // 输出：test foo
  ```

  其实就是封装普通函数

- `lambda`表达式

  因为`lambda`表达式本身是匿名函数，所以`std::function`也可以封装`lambda`表达式。

  ```cpp
  std::function<int(int, int)> func = [](int x, int y) {
      std::cout << "do something in lambda" << std::endl;
      return x + y;
  };
  std::cout << func(10, 20) << std::endl; // 输出：30
  
  // 特殊情况：如果lambda表达式无形参，可以不写std::function的模板参数
  std::function func = []() {
      std::cout << "do something in lambda" << std::endl;
      return 100;
  };
  std::cout << func() << std::endl;
  ```

- 非静态成员函数指针

  对于类的成员函数，需要结合类对象的实例和`std::bind`使用。

  ```cpp
  class MyClass {
  public:
      int multiply(int a, int b) {
          return a * b;
      }
  };
  
  int main() {
      MyClass obj; // 创建一个对象实例
      std::function<int(int, int)> func = std::bind(&MyClass::multiply, &obj, std::placeholders::_1, std::placeholders::_2);
  
      int res = func(2, 3); // 6
      std::cout << "res: " << res << std::endl;
  
      return 0;
  }
  ```

  > 注意：此时不存在特殊情况，即便类的成员函数无形参，也需要在创建`std::function`时指定模板参数。

- 静态成员函数指针

  ```cpp
  class MyClass {
  public:
      static int multiply() {
          return 100;
      }
  };
  
  int main() {
      MyClass obj; // 创建一个对象实例
      std::function func = &MyClass::multiply;
  
      int res = func(); // 100
      std::cout << "res: " << res << std::endl;
  
      return 0;
  }
  ```

  需要取地址，并且加上类域。

- 仿函数

  ```cpp
  class Functor {
  public:
      int operator()() {
          std::cout << "Functor called" << std::endl;
          return 100;
      }
  };
  
  std::function f2 = Functor(); // 如果对应函数没有形参也可以不填模板参数
  std::cout << f2() << std::endl;
  ```

## 原理