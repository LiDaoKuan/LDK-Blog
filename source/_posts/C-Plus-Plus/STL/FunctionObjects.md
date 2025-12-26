---
title: 函数对象、谓词和STL内建函数对象
date: 2025-07-06
tags: [Cpp, STL]
categories: Cpp
description: C++ 四种map
---

## 函数对象

### 概念

函数对象又称为**仿函数**，**本质上是一个类**，因其重载了`operator()`运算符后**可以像函数一样被调用**，因此被称为仿函数或者函数对象。

根据接收参数的数量，函数对象还可以分为：

- **一元函数对象：** 接受一个参数。
- **二元函数对象：** 接受两个参数。
- **多元函数对象：** 接受三个或更多参数（较少见，通过组合或更复杂的结构实现）。

### 基本使用

```cpp
#include <iostream> 

// 定义函数对象
class Add {
public:
    // 重载函数调用操作符 ()
    int operator()(int x, int y) const {
        return x + y; // 实现加法操作
    }
};

int main() 
{
    // 1. 实例化Add类的对象
    Add adder; 
    
    // 2. 调用函数一样使这个对象
    // 实际上是调用adder对象的operator()(2, 3)方法
    std::cout << "用实例化对象调用: " << adder(2, 3) << std::endl;

    // 3. 也可以通过匿名对象直接调用
    // Add() 是使用默认构造函数生成了临时对象, 然后用这个临时对象调用函数
    std::cout << "使用匿名对象调用: " << Add()(5, 7) << std::endl;
    
    return 0;
}
```

基础使用还是很简单的，没有复杂的内容。

## 谓词

### 概念

返回值是`bool`类型的函数对象称为**谓词**。根据接收参数不同，又分为：

- 如果`operator()`接收一个参数，就叫**一元谓词**。
- 如果`operator()`接收两个参数，就叫**二元谓词**。

举例：

```cpp
#include <iostream>

// 即是一元谓词, 也是二元谓词
class Test {
public:
    bool operator()(bool b) // 一元谓词
    {
        std::cout << "operator()(bool b) called" << std::endl;
        return b;
    }

    bool operator()(int x, int y) // 二元谓词
    {
        std::cout << "operator()(int x, int y) called" << std::endl;
        return x > y;
    }
};

int main() {
    Test()(12, 20);

    Test()(true);

    return 0;
}
```

上例中，`Test()`即是一元谓词，也是二元谓词。

### 谓词的用途

在C++ `STL`的内置算法中有很多函数都是有谓词这个参数的，比如大家常用的`sort()`排序算法，它的参数列表如下：

`void sort<_Ranlt>(const_Ranlt_First, const_Ranlt_Last, _Pr_Pred);`.

其第三个参数`_Pr_Pred`就是谓词，这个参数可以不用传，默认升序排序，但如果你想要降序排序，这个谓词参数就必须要传了。

例如下面代码：

```cpp
#include<iostream>
#include<string>
#include<vector>
#include<algorithm> 
using namespace std;
class compare
{
public:
	bool operator()(int v1,int v2)
	{
		return v1 > v2;
	}
};
void Print(int a[], int n)
{
	for (int i = 0; i < 10; ++i) {
		cout << a[i] << " ";
	}
}
int main()
{
	int arr[10] = { 8,5,7,2,9,4,1,0,3,6 };//乱序的数组
	cout << "升序打印：";
	sort(arr, arr + 10);
	Print(arr, 10);
    cout << "\n";
	//添加谓词参数
	cout << "降序打印：";
	sort(arr, arr + 10, compare()); // compare()是匿名(临时)函数对象
	Print(arr, 10);
}
```

## STL内建函数对象

STL中内建了一些函数对象，主要分为三类：

- 算术仿函数
- 关系仿函数
- 逻辑仿函数

使用内建仿函数时，必须包含头文件`functional`.

### 算术仿函数

| 名称            | 类型     | 功能      |
| --------------- | -------- | --------- |
| `plus<T>`       | 二元谓词 | 加法操作+ |
| `minus<T>`      | 二元谓词 | 减法操作- |
| `multiplies<T>` | 二元谓词 | 乘法操作* |
| `divides<T>`    | 二元谓词 | 除法操作/ |
| `modulus<T>`    | 二元谓词 | 取模操作% |
| `negate<T>`     | 一元谓词 | 取反操作~ |

使用示例：

```cpp
#include <iostream>
#include <functional>

int main() {
    std::multiplies<int> multiply;
    std::cout << "4 * 5 = " << multiply(4, 5) << std::endl;  // 输出：4 * 5 = 20
    
    plus<int> p;
	cout << "加法仿函数运算结果：" << p(123, 456) << endl;

	modulus<int> md;
	cout << "取模仿函数运算结果：" << md(35, 14) << endl;

	negate<int> n;//一元运算，下面只传一个参数
	cout << "取反仿函数运算结果：" << n(10) << endl;

    return 0;
}
```

### 关系仿函数

| 名称               | 类型     | 功能         |
| ------------------ | -------- | ------------ |
| `greater<T>`       | 二元谓词 | 大于比较>    |
| `greater_equal<T>` | 二元谓词 | 大于比较>=   |
| `less<T>`          | 二元谓词 | 小于比较<    |
| `less_equal<T>`    | 二元谓词 | 小于比较<=   |
| `equal_to<T>`      | 二元谓词 | 相等比较==   |
| `not_equal_to<T>`  | 二元谓词 | 不等于比较!= |

示例代码：

```cpp
#include <iostream>
#include <functional>

int main() {
    std::cout << "Is 10 greater than 3? " << std::greater<int>()(10, 3) << std::endl;  // 直接使用临时对象。输出：1（true）
    return 0;
}
```

### 逻辑仿函数

| 名称             | 类型     | 功能           |
| ---------------- | -------- | -------------- |
| `logical_and<T>` | 二元谓词 | 逻辑与操作&&   |
| `logical_or<T>`  | 二元谓词 | 逻辑或操作\|\| |
| `logical_not<T>` | 一元谓词 | 逻辑非操作!    |

示例代码：

```cpp
#include <iostream>
#include <functional>

int main() {
    std::cout << "true && false = " << std::logical_and<bool>()(true, false) << std::endl; // 输出：0（false）
    return 0;
}
```

## 函数适配器（重点！！！）

> 函数适配器允许对函数对象或普通函数进行转换，以适应特定的调用场景

### 绑定、取反适配器

#### `bind2nd`适配器

用于绑定**第二个**参数，并固定其值。作用是将二元谓词降价为一元谓词。

> `std::bind2nd`已弃用，可用`std::bind + std::placeholders`替代。

虽然已经弃用，但是还是看一边示例代码：

```cpp
#include <iostream>
#include <functional>
#include <vector>
#include <algorithm>

int main() {
    std::vector<int> v = {0, 1, 2, 3, 4, 5, 6};
    std::binder2nd<std::less<int>> less_than_4 = std::bind2nd(std::less<int>(), 4); // 绑定第二个参数，固定其值为4
    // 上面一行可以用这一行来替代：
    // auto less_than_4 = std::bind(std::less<int>(), std::placeholders::_1, 4);
    std::ptrdiff_t count = std::count_if(v.begin(), v.end(), less_than_4);
    std::cout << "Number of elements less than 4: " << count << std::endl; // 输出：4，总共4个小于4的值
    return 0;
}
```

#### `bind1st`适配器

用于绑定**第一个**参数，并固定其值。作用是将二元谓词降价为一元谓词。

> `std::bind1st`已弃用，可用`std::bind + std::placeholders`替代。

```cpp
#include <iostream>
#include <functional>
#include <vector>
#include <algorithm>

int main() {
    std::vector<int> v = {0, 1, 2, 3, 4, 5, 6};
    std::binder1st<std::greater<int>> greater_than_4 = std::bind1st(std::greater<int>(), 4);
    // 上面一行可以用这一行来替代：
    // auto greater_than_4 = std::bind(std::greater<int>(), std::placeholders::_1, 4);
    std::ptrdiff_t count = std::count_if(v.begin(), v.end(), greater_than_4);
    std::cout << "Number of elements less than 4: " << count << std::endl; // 输出：4，总共4个小于4的值.
    // 因为4在参数1的位置，而std::greater<int>(x, y)在x>y时返回true。所以此处得到的是比4小的值
    return 0;
}
```

#### `not1`和`not2`:

对函数对象的结果取反。

```cpp
#include <iostream>
#include <functional>
#include <vector>
#include <algorithm>

int main() {
    std::vector<int> v = {1, 2, 3, 4, 5, 6};
    auto greater_than_4 = std::bind1st(std::greater<int>(), 4);
    auto not_greater_than_4 = std::not1(greater_than_4); // 对greater_than_4的结果取反
    auto count = std::count_if(v.begin(), v.end(), not_greater_than_4);
    std::cout << "Number of elements not greater than 4: " << count << std::endl;  // 输出：3。总共3个不小于4的值
    return 0;
}
```

### 成员函数适配器

成员函数适配器将成员函数映射为普通函数，包括`std::mem_fun`和`std::mem_fun_ref`：

- `std::mem_fun`：适用于包含对象指针的容器。
- `std::mem_fun_ref`：适用于包含对象本身的容器。

上述两个函数皆已经弃用，`std::mem_fn`可以完成这两个函数的全部功能。

#### `std::mem_fun`：

```cpp
#include <iostream>
#include <vector>
#include <functional>
#include <algorithm>

class Student {
public:
    Student(int id) : id(id) {}
    void display() const {
        std::cout << "ID: " << id << std::endl;
        free();
    }

    void free() const {
        delete this;
    }

private:
    int id;
};

int main() {
    std::vector<Student *> students = {new Student(1), new Student(2), new Student(3)};
    std::for_each(students.begin(), students.end(), std::mem_fun(&Student::display));
    return 0;
}
```

#### `std::mem_fun_ref`：

```cpp
#include <iostream>
#include <vector>
#include <functional>
#include <algorithm>

class Student {
public:
    Student(int id) : id(id) {}
    void display() const {
        std::cout << "ID: " << id << std::endl;
    }
private:
    int id;
};

int main() {
    std::vector<Student> students = {Student(1), Student(2), Student(3)};
    std::for_each(students.begin(), students.end(), std::mem_fun_ref(&Student::display));
    return 0;
}
```

