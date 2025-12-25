---
title: std::future, std::promise与std::async
tags: [Cpp, 多线程, 并发]
categories: Cpp
date: 2025-08-06
---

### std::async

`std::async`是一个用于异步执行函数的模板函数，它返回一个 `std::future` 对象，该对象用于获取执行函数的返回值。关于`std::future`的具体细节，此处可以先忽略，只要能够看懂实例程序就行。

其函数声明余如下：

```cpp
template <typename _Fn, typename... _Args>
_GLIBCXX_NODISCARD future<__async_result_of<_Fn, _Args...>> async(std::launch __policy, _Fn &&__fn, _Args &&...__args);
```

由函数声明可以看出：该函数接收多个参数，其中**第一个参数是启动策略**，**第二个函数是要执行的函数**，剩下的参数就是执行函数需要的参数。

其中关于第一个参数：启动策略，可选值有：

- `std::launch::async`：保证异步行为，即传递函数将在单独的线程中执行。推荐使用。
- `std::lanuch::deferred`：执行函数将在调用`std::future::get()`或`std::future::wait()`时延迟执行（同步执行）。换句话说，执行函数将在需要结果时同步执行。
- `std::launch::async | std::launch::deferred`：在不指定启动策略时，默认的启动策略。执行函数可能同步执行，也可能异步执行。

使用举例：

```cpp
#include <iostream>
#include <future>
#include <chrono>
#include <thread>

// 定义一个异步任务
std::string fetchDataFromDB(std::string query) {
    // 模拟一个异步任务，比如从数据库中获取数据
    std::this_thread::sleep_for(std::chrono::seconds(5));
    std::cout << "fetchDataFromDB finished" << std::endl;
    return "Data: " + query;
}

int main() {
    // 使用 std::async 异步调用 fetchDataFromDB
    std::future<std::string> resultFuture = std::async(std::launch::async, fetchDataFromDB, "Data");

    // 在主线程中做其他事情
    std::cout << "Doing something else in main thread ..." << std::endl;

    // 从 future 对象中获取数据
    std::string dbData = resultFuture.get();
    std::cout << dbData << std::endl;

    return 0;
}
```

上述程序的输出：

```txt
Doing something else in main thread ...
fetchDataFromDB finished
Data: Data
```

`std::async`实际上是在执行函数时，传入了一个`std::promise`，然后单开一个线程执行，同时返回关联的`std::future`。方便外部获取结果。

### std::future和std::promise

#### std::future

##### 用途

`std::future`提供了访问异步操作结果的机制。`future`在中文中的意思就是"期望"。在C++中，有两种"期望"：

- 唯一期望（`unique futures`）：`std::future<>`。只能与一个指定事件关联。
- 共享期望（`shared futures`）： `std::shared_future<>`。能够关联多个事件。

实际上，`std::future`内部存储了一个将会被某个`promise`赋值的变量，并提供了访问该值的`get()`函数。如果`get()`函数被调用时，`promise`尚未赋值（`set_value()`），那么调用者线程将会阻塞等待，直到`promise`完成赋值。

正常情况下，`std::future`对象通常由一下三种方式创建或得到：

- `std::async`函数的返回值。上文已经讲过。

- `std::promise::get_future`函数。而调用该函数前肯定需要创建一个`promise`对象：

  `std::promise<int> promiseObj; // 创建一个promise对象，任务完成后设置int值`

- `std::packaged_task::get_future`函数。

其实`std::future`的构造函数是能用的（拷贝构造除外）：

```cpp
// default
future() noexcept;
// copy [deleted] 
future (const future&) = delete;
// move
future (future&& x) noexcept;s
```

##### std::future的状态

对一个`std::future`对象，存在有共享状态和无共享状态两种情况。

> 有共享状态：可用，可以调用`get()`函数。
>
> 无共享状态：不可用，此时调用`get()`函数会抛出异常。

有共享状态时又分为三种：`future_status::ready`，`future_status::timeout`和`future_status::deferred`。

`future_status::ready`：共享状态的标志已经变为`ready`，即对应的`std::promise`在共享状态上设置了值或者异常。

`future_status::timeout`：超时，即在规定的时间内共享状态的标志没有变为`ready`。

`future_status::deferred`：共享状态包含一个`deferred`函数。

##### 成员函数

- `std::future::valid()`：

  判断`std::future`是否拥有共享状态。可以简单理解为是否有效。主要用于应对下面两种情况：

  - 因为`std::future`是可移动的，所以在对象被`std::move`后，原对象会无效，也就是不可用（无共享状态），此时对原对象调用`get()`成员函数将会导致程序抛出异常。例如下面的程序段：

    `std::future<int> futureObj_move = std::move(futureObj); futureObj_move.get(); // 会抛出异常`

  - 当`future`对象调用`get()`函数之后，该对象将变得无效（无共享状态）。再次调用`get()`都会导致程序抛出异常。例如：

    `int sum = futureObj.get(); sum = futureObj.get();`

    连续调用两次`get()`函数，第二次会抛出异常。

  以上两种情况，都可以用`valid()`来检测：
  ` if (futureObj.valid()) { sum = futureObj.get(); }`

  这样就可以避免抛出异常。当然多线程时，这里还要考虑线程安全问题。

- `std::future::get()`：

  阻塞式获得共享状态的值，如果 `future` 对象调用 `get()` 时，共享状态标志尚未被设置为 `ready`，那么本线程将阻塞至其变为 `ready`。

- `std::future::wait()`：

  阻塞等待共享状态标志变为`ready`，如果在无共享状态下调用（`valid()`函数返回`false`），将会抛出异常。

- `std::future::wait_for()`：

  与`wait()`不同，`wait_for()`只会允许为此等待一段时间`_Rel_time`，耗尽这个时间共享状态标志仍不为`ready`，`wait_for()`一样会返回。

- `std::future::wait_until()`：

  与`wait_for()`类似的逻辑，只不过`wait_until()`参考的是绝对时间点。到达时间点`_Abs_time`的时候，`wait_until()`就会返回，如果没等到`ready`的话，`wait_until`一样会返回。

- `std::future::share()`：

  返回一个`std::shred_future`对象，调用该函数之后，`future`对象不和任何共享状态关联，也就不再是`valid`的了。例如：

  `futureObj.share(); int sum = futureObj.get();`

  后面一句会报错，因为前面使用了`share()`，`futureObj`已经不再有效。

#### std::promise

`std::promise`的作用就是提供一个不同线程之间的数据同步机制，它可以存储一个某种类型的值，并将其传递给对应的`future`， 即使这个`future`与`promise`不在同一个线程中也可以安全的访问到这个值。

可以通过`get_future()`来获取与一个`promise`对象相关联的`future`对象，调用该函数之后，两个对象共享相同的共享状态(shared state)。

`set_value()`函数可以设置共享状态的值，此后`promise`的共享状态标志变为`ready`。每个`std::promise`只能调用一次`set_value()`。

`set_exception()`函数可以设置异常，在这之后对与之相关联的`std::future`的`get()`调用将抛出这个异常。

#### 简单使用案例：

主要是`std::promise`的值传递问题。

版本一：

```cpp
#include <iostream>
#include <thread>
#include <mutex>
#include <atomic>
#include <future> //std::future std::promise
#include <cmath>

void fun(int x, int y, std::promise<int> promiseObj) // 注意最后一个参数是普通传参，没有引用也没有指针
{
    int sum = 0;
    for (int i = 0; i < pow(x, y); ++i) {
        sum += i; // 模拟复杂任务
    }
    promiseObj.set_value(sum);
    std::cout << "value has been set" << std::endl;
}

int main() {
    int a = 10;
    int b = 8;

    // 声明一个promise类
    std::promise<int> promiseObj;
    // 将future和promise关联
    std::future<int> futureObj = promiseObj.get_future();

    std::thread t(fun, a, b, std::move(promiseObj)); // 此处必须使用std::move

    // 获取线程的"返回值"
    std::cout << "ready to get value" << std::endl;
    int sum = futureObj.get();
    std::cout << "sum=" << sum << std::endl; // 输出：18

    t.join();
    return 0;
}
```

版本二：

```cpp
#include<iostream>
#include<thread>
#include<mutex>
#include<atomic>
#include<future>  //std::future std::promise

void fun(int x, int y, std::promise<int>& promiseObj) // 注意此处promise是引用传参！
{
	int sum = 0;
    for (int i = 0; i < pow(x, y); ++i) {
        sum += i; // 模拟复杂任务
    }
    promiseObj.set_value(sum);
    std::cout << "value has been set" << std::endl;
}

int main()
{
	int a = 10;
	int b = 8;

	// 声明一个promise类
	std::promise<int> promiseObj;
	// 将future和promise关联
	std::future<int> futureObj = promiseObj.get_future();

	std::thread t(fun, a, b, std::ref(promiseObj)); // 此处必须用std::ref
    
	// 获取线程的"返回值"
    std::cout << "ready to get value" << std::endl;
    int sum = futureObj.get();
    std::cout << "sum=" << sum << std::endl; // 输出：18

    t.join();
	return 0;
}
```

版本三：

```cpp
#include <iostream>
#include <thread>
#include <mutex>
#include <atomic>
#include <future> //std::future std::promise
#include <cmath>

void fun(int x, int y, std::promise<int>* promiseObj) // 注意此处传递的是指针
{
    int sum = 0;
    for (int i = 0; i < pow(x, y); ++i) {
        sum += i; // 模拟复杂任务
    }
    promiseObj->set_value(sum);
    std::cout << "value has been set" << std::endl;
}

int main() {
    int a = 10;
    int b = 8;

    // 声明一个promise类
    std::promise<int> promiseObj;
    // 将future和promise关联
    std::future<int> futureObj = promiseObj.get_future();

    std::thread t(fun, a, b, &(promiseObj)); // 注意此处直接取地址！！！

    // 获取线程的"返回值"
    std::cout << "ready to get value" << std::endl;
    int sum = futureObj.get();
    std::cout << "sum=" << sum << std::endl; // 输出：18

    t.join();
    return 0;
}
```

为什么会有三种版本，对应三种不同的传值方式呢？本质是因为`std::promise`不可拷贝（拷贝函数被删除），但可以移动（移动构造可用）。

| 特性                    |   版本一（值传递+move）    |  版本二（引用传递+ref）  |    版本三（指针传递）    |
| ----------------------- | :------------------------: | :----------------------: | :----------------------: |
| **promise变量的所有权** |     完全转移给线程函数     | 共享（主线程保持所有权） | 共享（主线程保持所有权） |
| **生命周期**            |      线程函数负责销毁      |      主线程负责销毁      |      主线程负责销毁      |
| **内存安全**            | ✅ 最安全（无悬空引用风险） |      ⚠️ 需要正确同步      |      ⚠️ 需要正确同步      |
| **代码清晰度**          | ✅ 最清晰（明确所有权转移） |          ✅ 良好          |     ❌ 较低（C风格）      |
| **标准推荐**            |           ✅ 首选           |         ✅ 可接受         |         ❌ 不推荐         |
