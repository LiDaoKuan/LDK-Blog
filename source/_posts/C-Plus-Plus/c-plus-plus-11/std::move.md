---
title: 左值/右值引用和std::move
tags: [Cpp, 移动语义]
categories: Cpp
date: 2025-07-06
---

### 左值和右值

要想了解std::move，需要先了解**左值**和**右值**，以及**左值引用**和**右值引用**。先说简单的**判断左值和右值的方法**：

- **左值**：

  **可以取地址、可以位于等号左边**。也既：可以出现在等号（赋值运算符）左边，也可以出现在等号右边（取地址或者赋值给其他变量）。例如：在`int a = 10;`中，变量`a`即是**左值**。我们同样可以对变量`a`取地址：`int* b = &a`，此处`a`和`b`都是左值。再比如，可以将变量`a`赋值给其他变量：`int c = a`，此处`c`和`a`都是左值。

- **右值**：
  **没法取地址，只能位于等号（赋值运算符）右边**。例如：在下面代码中，字符串`"123"`和整数`100`都是右值。

  ```cpp
  std::string str = "123";
  int num = 100;
  ```

  因为它们都只能出现在**赋值运算符**右边，且不能取地址，也不能出现在**赋值运算符**左边。在代码中写`"123" = str`是非法的，写`string* p = &"123"`也是非法的，编译器都是会报错的。

### 左值引用和右值引用
知道左值和右值之后，再来将左值引用和右值引用。回忆以下引用：**给变量取别名**。而引用的本质其实是指针，只是没有指针那么灵活。

- 左值引用：

  其实就是普通的引用，又或者说：**对左值的引用**。同时，**一般的左值引用无法指向右值**，<mark>const左值引用除外</mark>。例如：
  ```cpp
  int a = 100;
  int& b = a;
  
  int& num = 100; // 左值引用指向了右值, 会编译失败
  const int& temp = 100; // 编译通过，const左值引用可以指向右值
  ```

  上面代码中，变量`b`是左值`a`的引用，所以`b`就是左值引用。

  为什么`const`引用可以指向右值？因为`const`引用不会修改指向的值，所以可以指向右值。

- **右值引用**：

  顾名思义，对**右值的引用**，也就是**给右值取别名**。但是注意：<mark>右值引用有特定的语法</mark>：`int&& a=100`，此时`a`就是右值引用。注意`a`前面是两个`&`！另外，**右值引用也不能指向左值**。例如：

  ```cpp
  int &&ref_a_right = 5; // ok
   
  int a = 5;
  int &&ref_a_left = a; // 编译不过，右值引用不可以指向左值
   
  ref_a_right = 6; // 右值引用的用途：可以修改右值
  ```

- **左值引用和右值引用都是左值**：

  为什么呢？因为**左值引用和右值引用本身都可以取地址，也都可以位于赋值运算符左边**。且看测试代码：
  ```cpp
  #include <iostream>
  
  void change(int&& right_value) {
      right_value = 8;
  }
   
  int main() {
      int a = 5; // a是个左值
      int &ref_a_left = a; // ref_a_left是个左值引用
      int &&ref_a_right = std::move(a); // ref_a_right是个右值引用
   
      change(a); // 编译不通过, a是左值, change参数要求右值
      change(ref_a_left); // 编译不通过, 左值引用ref_a_left本身也是个左值
      change(ref_a_right); // 编译不通过, 右值引用ref_a_right本身也是个左值
       
      change(std::move(a)); // 编译通过
      change(std::move(ref_a_right)); // 编译通过
      change(std::move(ref_a_left)); // 编译通过
   
      change(5); // 当然可以直接接右值，编译通过
       
      std::cout << &a << ' '; // 输出0x7fffffffd430
      std::cout << &ref_a_left << ' '; // 输出0x7fffffffd430
      std::cout << &ref_a_right; // 输出0x7fffffffd430
      // 打印这三个左值的地址，都是一样的
  }
  ```

### std::move

`std::move`接收左值，返回右值引用。**右值引用在此处是右值**。也就是说：`std::move`可以将一个左值强制转换为一个右值。`std::move`并**不是**将一个变量的值**移动**到另一个变量中。而是将资源的所有权进行了移动。同时，`std::move`对于基本类型（如`int, char, bool`等）的作用和拷贝操作相同，也就是说，**对基本类型执行移动操作在效果上完全等同于拷贝操作**。但对于类类型（如`std::string`），对其执行移动操作将会**转移资源的所有权**，但资源所处的内存地址不变。换句话说：**对一个对象使用std::move后，对象内的资源还是存储在原来的位置，只是拥有它的对象变成了另一个右值对象**。借助下面代码理解：

```cpp
#include <iostream>
#include <utility>
#include <vector>
#include <string>

int main() {
    std::string str = "123";
    std::vector<std::string> v;
    // 调用常规的拷贝构造函数，新建字符数组，拷贝数据
    v.push_back(str);
    std::cout << "After copy, str is \"" << str << "\"\n";
    // 调用移动构造函数，掏空str，掏空后，最好不要使用str
    v.push_back(std::move(str));
    std::cout << "After move, str is \"" << str << "\"\n";
    std::cout << "The contents of the vector are \"" << v[0] << "\", \"" << v[1] << "\"\n";
}
```

上面代码输出：
```shell
After copy, str is "123"
After move, str is ""
The contents of the vector are "123", "123"
```

可见，对变量`str`执行`std::move`后，它内部的字符串变为了空串。这是因为在标准库实现的`std::string`的移动构造函数中，内部存储字符串的`char*`指针赋给了新对象，原对象`str`的`char*`指针会指向空串，以此转移资源的所有权。

### std::move的返回值

上面说了：`std::move`接收左值，返回右值引用。**不是说将左值强制转换为右值吗？那不应该返回右值吗？怎么返回右值引用了？右值引用是右值吗？**写段代码验证一下：

```cpp
using std::string;

string str = "123";
string* p = &std::move(str); // 此处报错了：expression must be an lvalue or a function designator
```

上方代码报错：**表达式必须是左值或函数指示符**，什么意思？意思就是`std::move`返回的不是一个左值，那是什么？当然是右值。对右值取地址当然会报错。前面说了，`std::move`返回右值引用，从哪里看出来它返回右值引用呢？将上述代码粘贴到`VSCode`中，鼠标悬浮于`std::move`处，能看到：

![image-1](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20251222192650521.png)

也就是说，此处`std::move`实际上调用的是：

```cpp
constexpr std::string &&std::move<std::string &>(std::string &__t) noexcept
```

这个函数，这个函数的返回值是`std::string &&`类型，这不就是右值引用吗。

结合我们前面所说：`std::move`返回的是右值，现在又是右值引用。所以：<mark>右值引用作为函数返回值时是右值</mark>。

### 右值引用与`std::move`的应用场景

#### 实现移动语义

```cpp
#include <iostream>
#include <utility>
#include <string>
#include <cassert>

class Array {
public:
    Array(int size) {
        this->data_ = new std::string[size];
    }
    // 初始化列表构造函数
    Array(std::initializer_list<std::string> list) : size_(list.size()) {
        if (size_ > 0) {
            this->data_ = new std::string[size_];
            // 复制初始化列表中的元素
            std::copy(list.begin(), list.end(), data_);
        } else {
            this->data_ = nullptr;
        }
    }
    ~Array() {
        delete[] this->data_;
    }

    // 移动构造函数
    Array(Array &&arr) noexcept {
        std::cout << "Array move constructor" << std::endl;
        if (this == &arr) {
            return;
        }
        data_ = arr.data_;
        size_ = arr.size_;
        // 为防止temp_array析构时delete data，提前置空其data_
        arr.data_ = nullptr;
        arr.size_ = 0;
    }

    // 拷贝赋值函数
    Array &operator=(const Array &arr) {
        std::cout << "Array Copy assign" << std::endl;
        if (this->data_ != nullptr) {
            delete[] this->data_;
        }
        if (arr.size_ == 0) {
            data_ = nullptr;
            size_ = 0;
            return *this;
        }
        this->size_ = arr.size_;
        data_ = new std::string[this->size_];
        for (int i = 0; i < size_; ++i) {
            this->data_[i] = arr.data_[i];
        }
        return *this;
    }

    // 移动赋值函数
    Array &operator=(Array &&arr) noexcept {
        if (this == &arr) {
            return *this;
        }
        std::cout << "Array move" << std::endl;
        this->size_ = std::move(arr.size_);
        this->data_ = std::move(arr.data_);
        arr.data_ = nullptr;
        arr.size_ = 0;
    }

    // 重载索引运算符
    std::string &operator[](int i) {
        if (i < this->size_) {
            return data_[i];
        }
        std::cout << "Array Out Of Bounds" << std::endl;
        assert(false);
    }

    int size() {
        return this->size_;
    }

private:
    std::string *data_;
    int size_;
};

int main() {
    Array arr_1{"zhangsan", "lisi", "wangwu", "zhaoliu"};
    Array arr_2(std::move(arr_1));
    // const Array arr_3{"12", "34", "56"};
    // Array arr_4(std::move(arr_3)); // 报错：对const变量使用std::move将会退化为拷贝操作，但是Array类中没有实现拷贝构造函数。
    if (arr_1.size() == 0) {
        std::cout << "arr_1 is empty" << std::endl;
    }
    for (int i = 0; i < arr_2.size(); ++i) {
        std::cout << arr_2[i] << " ";
    }
    std::cout << "\n";
    return 0;
}
```

上面代码中，使用`std::move`时，调用了移动构造函数。移动构造函数更改了资源的所有权，避免了数据的拷贝。

<mark>注意</mark>：不能对`const`变量使用`std::move`期待移动！