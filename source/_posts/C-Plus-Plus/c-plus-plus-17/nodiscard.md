---
title: C++ nodiscard
tags: [Cpp, 语法]
categories: Cpp
date: 2025-07-06
---

## nodiscard

#### 用于标记函数的返回值：

`[[nodiscard]] int Compute();`

当调用该函数却不赋值返回结果时，将收到警告：

``````cpp
void Foo() {
    Compute();
}
``````

````cpp
warning: ignoring return value of 'int Compute()', declared with attribute nodiscard
````

#### 标记整个类型

```cpp
[[nodiscard]]
struct ImportantType {};

ImportantType CalcSuperImportant();
```

每当调用任何返回`ImportantType`的函数时，都会收到警告。

#### 使用注意

过多使用该关键字可能导致编译器编译时出现大量`warning`。