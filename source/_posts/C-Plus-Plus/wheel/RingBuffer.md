---
title: C++ RingBuffer实现
date: 2026-02-21
updated: 2026-02-22
tags: [轮子, C++， RingBuffer, CAS(compare and swap)]
categories: 轮子
description: C++ 环形缓冲区(RingBuffer)实现
---

本文需要先了解：原子操作和内存序

### 什么是RingBUffer

RingBuffer就是环形缓冲区，或者说是用数组实现的循环队列，通过取模运算形成逻辑上的循环。RingBuffer主要用于解决**生产者-消费者问题**（其实就是队列的用法）。但是RingBuffer相对于用链表实现的队列有明显的优势：

- 固定内存：事先为数组分配空间，避免动态内存分配
- 内存连续：数组的内存是连续的，数据在内存中连续存储，CPU缓存友好
- 高效覆盖：在某些场景下，缓冲区满后可以直接覆盖旧数组。
- 空间占用小：相比于链表实现的队列，RingBuffer不需要为每个节点都分配额外的指针空间。

### SPSC场景实现

SPSC 是指：Single Producer, Single Consumer，译为：单生产者单消费者。也就是说，这种实现**只适用于一个线程读取数据，一个线程写入数据**的场景。而在这种场景下，ringbuffer的实现可以高度优化，从而实现极高的性能。

通常，在并发编程中，我们经常使用互斥锁（`std::mutex`）来保护共享数据。但是锁机制存在一定的问题：

- 性能开销：每次加锁和解锁都是一次操作系统**内核调用**，会涉及系统上下文切换，在高并发场景下会严重影响性能。
- 线程阻塞：如果一个线程持有锁，其他线程想要获取这把锁就必须等待。
- 复杂性问题：使用锁容易引发死锁（Deadlock）和优先级反转（Priority Inversion）等棘手的问题。

SPSC 场景下的 RingBuffer 实现的关键就在于**无锁**。也就是说，不使用互斥锁，自旋锁等阻塞同步原语，而是使用现代CPU提供的原子操作（Atomic Operations）和内存屏障（Memory Fences）来确保数据在不同线程中的安全可见性和一致性。

#### 数据结构

一个固定大小的数组（作为环形缓冲区），两个索引或指针。

- `head`: 由消费者线程持有并且**唯一修改**，它指向下一个要读取的元素的位置。
- `tail`: 由生产者线程持有并且**唯一修改**，它指向下一个要写入的元素的位置。

为了保证在没有锁的情况下，一个线程对索引的更新能被另一个线程正确地观察到，head 和 tail 索引必须是原子类型（`std::atomic<size_t>`）。

#### 内存顺序（Memory Order）

这是无锁编程中最为精妙也最难的部分，为了确保数据和索引的同步，必须使用正确的内存序。更详细的内存序使用参考：[C++内存序](https://ldkblog.top/undefined/C-Plus-Plus/%E5%B9%B6%E5%8F%91/%E5%86%85%E5%AD%98%E5%BA%8F/)

- 生产者线程在更新`tail`时，需要使用`std::memory_order_release`.
    意思是：保证在 `tail` 索引被更新之前，所有对缓冲区中元素数据的写入操作都已经完成，并且对其他线程可见。这就像一个屏障，防止它之前的写操作被重排到它之后。
- 消费者线程在更新`head`时，需要使用`std::memory_order_`.
    意思是：保证在读取 `tail` 索引之后，才能去读取缓冲区中的数据。它与生产者的 release 配对，保证消费者能看到生产者写入的所有数据。

#### 伪共享（False Sharing）

学过操作系统的都知道，CPU内部存在多级缓存（L1,L2,L3），CPU将最近使用的数据预先读取到Cache中，下次再访问同样数据的时候，可以直接从速度比较快的CPU缓存中读取，避免从内存或磁盘读取拖慢整体速度。

CPU缓存的最小单位就是缓存行，缓存行大小依据架构不同有不同大小，最常见的有64Byte和32Byte，CPU缓存从内存取数据时以缓存行为单位进行，每一次都取需要读取数据所在的整个缓存行，即使相邻的数据没有被用到也会被缓存到CPU缓存中（这里又涉及到局部性原理，感兴趣请自行百度）。

##### 缓存一致性

在单核CPU情况下，上述方法可以正常工作，可以确保缓存到CPU缓存中的数据永远是“干净”的，因为不会有其他CPU去更改内存中的数据，但是在多核CPU下，情况就变得更加复杂一些。多CPU中，每个CPU都有自己的私有缓存（可能共享L3缓存），当一个CPU1对Cache中缓存数据进行操作时，如果CPU2在此之前更改了该数据，则CPU1中的数据就不再是“干净”的，即应该是失效数据，缓存一致性就是为了保证多CPU之间的缓存一致。

Linux系统中采用MESI协议处理缓存一致性，具体协议此处不做讨论。只需要知道：MESI协议值能够保证多核CPU的不同核心之间的缓存一致性。比如CPU1对一个缓存行执行了写入操作，则此操作会导致其他CPU的该缓存行进入Invalid无效状态，CPU需要使用该缓存行的时候需要从内存中重新读取。

进而，造成了伪共享：

1. 线程A在CPU1上运行，对CPU1中的某个缓存行执行了写入操作。导致CPU其他核心的该缓存行进入**失效**状态。
2. 线程B在CPU2上运行，对CPU2中的该缓存行执行读取操作，发现是**脏数据**（失效状态）。于是，CPU2决定从内存或者其他核心中重新读取该缓存行上的数据。
3. 这种情况肯定不会只发生一次，更多时候是频繁发生，但其并不会导致错误，而是会影响性能。即：CPU频繁出现缓存失效，频繁更新缓存，最终导致性能下降。

总结：伪共享是指在多线程环境中，多个线程访问不同的变量，但这些变量恰好位于同一个缓存行中，从而导致不必要的缓存一致性开销。

在下方我们实现的 SPSC 队列中，head_ 和 tail_ 是两个频繁被不同线程访问的变量。为了避免它们之间的伪共享，我们使用 alignas(CACHE_LINE_SIZE) 将它们对齐到缓存行的边界上。这样可以确保它们位于不同的缓存行中，从而减少缓存失效的可能性，提高性能。

```cpp
#ifndef SPSC_QUEUE_H
#define SPSC_QUEUE_H

#include <vector>
#include <atomic>
#include <cstddef> // for size_t
#include <new>     // For std::hardware_destructive_interference_size

// ----- 关键性能优化: 缓存行对齐 -----
// 在 C++17 之前，我们通常会硬编码一个值，比如64
// C++17 提供了标准的宏来获取这个值，以提高可移植性

#ifdef __cpp_lib_hardware_interference_size
constexpr size_t CACHE_LINE_SIZE = std::hardware_destructive_interference_size;
#else
// 64 字节是现代 x86 CPU 缓存行的常见大小，是一个安全的选择
constexpr size_t CACHE_LINE_SIZE = 64;
#endif

template <typename T>
class SPSCQueue
{
public:
    explicit SPSCQueue(size_t capacity) : capacity_(capacity + 1), // +1: 用于留一个空位，方便判断队空和队满
                                          buffer_(capacity + 1)
    {
        // 确保T是可移动构造或者可移动赋值的类型
        static_assert(std::is_move_constructible<T>::value, "T must be move constructible");
        static_assert(std::is_move_assignable<T>::value, "T must be move assignable")
    }

    // 禁止拷贝和赋值
    SPSCQueue(const SPSCQueue &) = delete;            // 删除拷贝构造
    SPSCQueue &operator=(const SPSCQueue &) = delete; // 删除赋值

    ~SPSCQueue()
    {
        // 析构函数：确保队列中所有剩余的 T 对象都被正确销毁
        T dummy;
        while (try_dequeue(dummy))
        {
            // 循环出队，直到队列为空
            // dummy的析构函数会在每次循环结束时被调用
        }
    }

    // [生产者线程调用] 尝试将一个元素入队, 注意这里T&&不是万能引用, 因为对于类的函数, 在编译时由于T作用在成员变量上, 类模板参数T已经确定.
    bool try_enqueue(T &&value)
    {
        // 生产者本地读取自己的tail，不用同步，因为只有它自己写
        const auto current_tail = tail_.load(std::memory_order_relaxed);
        const auto next_tail = (current_tail + 1) % capacity_; // 计算下一个tail位置, 用于判断队列是否已满

        // 读取消费者的head位置， 用于判断队列是否已满， 因此需要使用 acquire 语义确保读取到最新值
        // 因为留一个空位作为队列满的标志, 所以当 next_tail == head 时表示队列已满
        if (next_tail == head_.load(std::memory_order_acquire))
        {
            return false;
        }

        // 将数据放入缓冲区
        buffer_[current_tail] = std::move(value);

        // 写入完成后，更新 tail 位置，使用 release 语义确保数据写入对消费者可见
        tail_.store(next_tail, std::memory_order_release);

        return true;
    }

    // 左值重载
    bool try_enqueue(const T &value)
    {
        T tmp = value;
        return try_enqueue(std::move(tmp));
    }

    // [消费者线程调用] 尝试从队列中取出一个元素，value 用于接收出队元素的引用
    bool try_dequeue(T &&value)
    {
        // memory_order_relaxed: 此操作只与本线程相关。
        const auto current_head = head_.load(std::memory_order_relaxed);

        // memory_order_acquire: 确保我们能够看到生产者线程对 tail_ 的最新更新
        // 它与生产者 enqueue 中的 release 操作配对
        if (current_head == tail_.load(std::memory_order_acquire))
        {
            return false;
        }

        // 从缓冲区中取走数据
        value = std::move(buffer_[current_head]);

        // memory_order_release: 确保 head_ 的更新对生产者可见
        // 这样生产者就能知道一个槽位被释放了
        // 它与生产者 enqueue 中的 acquire 操作配对
        head_.store((current_head + 1) % capacity_, std::memory_order_release);

        return true;
    }

    /**
     * @brief 获取队列的近似大小
     * @note 在并发环境下，返回的值可能在读取之后就立即过时了
     * 主要用于监控和调试
     */
    size_t size() const
    {
        const auto current_tail = tail_.load(std::memory_order_acquire);
        const auto current_head = head_.load(std::memory_order_acquire);

        if (current_tail > current_head)
        {
            return current_tail - current_head;
        }
        return capacity_ + current_tail - current_head;
    }

    bool empty() const
    {
        return size == 0;
    }

private:
    const size_t capacity_;
    std::vector<T> buffer_;

    // ----- 避免伪共享（False Sharing） -----
    // head_ 和 tail_ 会被不同核心上的不同线程高频访问
    // alignas 确保它们位于不同的缓存行，避免一个线程
    // 的写操作导致另一个线程的缓存行失效，从而大幅提升性能
    alignas(CACHE_LINE_SIZE) std::atomic<size_t> head_{0}; // 初始化为0
    alignas(CACHE_LINE_SIZE) std::atomic<size_t> tail_{0};
};

#endif
```

### MPMC场景实现

MPMC 是指：Multiple-Producer, Multiple-Consumer，译为：多生产者多消费者。即：

- 任意数量的生产者线程同时向队列中添加元素。
- 任意数量的消费者线程同时从队列中取出元素。

要实现 MPMC 的队列，核心挑战是：**双端竞争与ABA问题**

#### 双端竞争（Double-Ended Contention）：

- 生产者端：多个生产者线程会同时竞争，试图更新队列的 tail（尾部）指针。
- 消费者端：多个消费者线程会同时竞争，试图更新队列的 head（头部）指针。

在 SPSC 中，两端都没有竞争。在 MPSC/SPMC 中，只有一端存在竞争。而在 MPMC 中，两端都存在激烈的竞争，这使得简单的原子指针更新变得不可行，必须使用更复杂的同步原语，如 CAS (Compare-And-Swap) 循环。

#### ABA问题：

这是无锁编程中一个非常著名且致命的陷阱，在 MPMC 的朴素实现中极易出现。

假设有两个线程 T1 和 T2, 线程 T1 读取内存地址 P 的值为 A。然后 T1 被操作系统挂起。

> 在并发场景下，线程被挂起后，其他线程可能会修改共享数据，这就为 ABA 问题的发生创造了条件。

与此同时，线程 T2 修改 P 的值为 B，然后又修改回 A。

T1 恢复执行，它检查 P 的值，发现仍然是 A。T1 错误地认为从它上次读取到现在什么都没有改变，于是继续执行后续操作。

在 MPMC 队列中，这种情况可能发生在 head 或 tail 指针上。这种情况是非常危险的，因为它可能导致数据结构的状态被错误地解释，进而引发数据损坏或程序崩溃。

假设一个基于**链表**的队列，线程 T1 准备对头节点 head（其地址为 A）执行出队操作。但此时 T1 挂起了， 在 T1 被挂起时，线程 T2 将 A 节点出队、销毁，然后又有一个新节点恰好在相同的内存地址 A 处被分配。当 T1 恢复时，它看到的 head 地址仍然是 A，但这个 A 已经是一个全新的、不相关的节点了（因为这是一个基于链表的队列）。如果 T1 继续操作，就会导致数据损坏或程序崩溃。

再举个银行转账的例子：

假设张三银行卡有 100 块钱余额，且假定银行转账操作就是一个单纯的 `CAS`（compare and swap） 命令，对比余额旧值是否与当前值相同，如果相同则发生扣减/增加，我们将这个指令用 `CAS(origin,expect)` 表示。于是，我们看看接下来发生了什么：

1. 张三在 ATM 1 转账 100 块钱给李四；
2. 但是 ATM 1 出现了网络拥塞的原因，卡住了，这时候张三跑到旁边的 ATM 2 再次操作转账；
3. ATM 2 正常执行了转账操作 `CAS(100, 0)`，**张三的账户余额变为了 0**。
4. 王五此时又给张三账户上转了 100，此时**张三账户余额为 100**。
5. 此时 ATM 1 网路恢复，**发现张三账户余额为100，以为刚刚没有转账成功**，继续执行刚刚的转账操作 `CAS(100, 0)`。**张三账户余额又变为 0**。

问题来了，张三本意是给李四转100, 但因为网络拥堵，在不同的ATM上尝试了两遍。结果两遍都成功了，这显然不符合张三的本意。假设我们作为银行系统设计者和开发者，不接受这种情况存在，那我们就需要着手处理这种 ABA 问题了，如何解决，此处略过，后面会说。

#### 实现策略

实现一个正确且高效的 MPMC 无锁队列是个大难题。工业界主要采用以下几种经过验证的算法。

##### Michael-Scott 队列

最常见的 MPMC 无锁队列算法，基于无锁链表实现

- 数据结构：一个单向链表，包含 head 和 tail 两个原子指针。

- 哨兵节点 (Sentinel Node)：队列初始化时包含一个“哑节点”（dummy node），`head` 和 `tail` 都指向它。这个哨兵节点简化了边界条件（空队列/单元素队列），并有效地将生产者和消费者的竞争点分离开。

- 入队 (Enqueue)：

    1. 创建一个新节点。

    2. 使用 CAS 循环，尝试将新节点链接到当前 `tail` 节点的 `next` 指针上。

    3. 成功后，再尝试更新 `tail` 指针指向新的尾节点。

- 出队 (Dequeue)：

    1. 使用 CAS 循环，尝试将 `head` 指针移动到它的下一个节点 (`head->next`)。

    2. 成功后，旧的 head（现在是哨兵节点）就可以被安全地回收了。

> 解决 ABA 问题：通常通过“标记指针” (Tagged Pointer) 或版本计数器 (Version Counter) 来解决。即: 将指针和 一个计数器打包成一个更大的原子类型（如 128 位），每次修改指针时都增加计数器。CAS 操作需要同时比较指针和计数器，确保两者都未被改变。

##### 现代高性能实现 (基于RIngBuffer)

虽然 Michael-Scott 队列是无界的（unbounded），但其性能通常受限于**内存分配**和**链表遍历**。现代很多高性能 MPMC 队列是有界的（bounded），并且基于环形缓冲区，因为这能更好地利用 CPU 缓存。

MPMC 的 RingBuffer 实现远比 SPSC 的 RingBuffer 复杂，其核心思想是：**给每个槽位加上版本号或者序列号，以协调生产者和消费者**。

基本思路：

维护两个原子计数器， `enqueue_ticket` 和 `dequeue_ticket` .

- 生产者：
    1. 原子地获取并递增 `enqueue_ticket` 得到一个唯一的入队”票号“。
    2. 计算该票号对应的缓冲区索引： `idx = ticket % capacity` .
    3. 自旋等待，直到 `buffer[idx]` 的版本号等于其票号，表示消费者已经消费完该槽位的旧数据，可以写入了。
    4. 写入数据。
    5. 将 `buffer[idx]` 的版本号 + 1， 以通知消费者数据已经准备好。
- 消费者：
    1. 原子地获取并且递增 `dequeue_ticket` 得到一个唯一的出队“票号”。
    2. 计算该票号对应的缓冲区索引： `idx = ticket % capacity` .
    3. 在自旋等待，直到 `buffer[idx]` 的版本号等于其票号，表示生产者已经写入新数据，可以消费了。
    4. 读取数据。
    5. 将 `buffer[idx]` 的版本号 + 1， 以通知生产者数据已经被消费。

这种设计将对 `head`/`tail` 指针的直接竞争，转化为了对槽位版本号的等待，在很多场景下能提供更高的吞吐量。

#### MPMC 场景的消息队列（基于链表）

> 注意：该版本实现的整体逻辑没问题，但是代码简化了部分操作（只保证操作逻辑正确），不能直接用！

```cpp
#ifndef MPMC_QUEUE_H
#define MPMC_QUEUE_H

#include <atomic>
#include <thread>

template <typename T>
class MPMCQueue
{
private:
    struct Node
    {
        T data;
        std::atomic<Node *> next;

        Node(T val) : data(std::move(val)), next(nullptr);
    };

    // 缓存行对齐以避免伪共享
    alignas(64) std::atomic<Node *> head_;
    alignas(64) std::atomic<Node *> tail_;

public:
    MPMCQueue()
    {
        // 关键：创建一个哨兵节点，简化边界条件
        // 队列初始化时，head_ 和 tail_ 都指向这个节点
        Node *sentinel = new Node(T{}); // 这里的T是默认构造的哨兵数据
        head_.store(sentinel);
        tail_.store(sentinel);
    }

    ~MPMCQueue()
    {
        // 清理所有剩余的节点
        T tmp;
        while (try_dequeue(tmp))
        {
        }
        // 删除最后的哨兵节点
        delete head_.load();
    }

    // 禁止拷贝和赋值
    MPMCQueue(const MPMCQueue &) = delete;
    MPMCQueue &operator=(const MPMCQueue &) = delete;

    /**
     * @brief [多生产者线程调用] 尝试将一个元素入队。
     */
    void enqueue(T value)
    {
        Node *new_node = new Node{std::move(value)};

        // CAS 循环：持续尝试，直到成功将新节点链接到链表尾部
        while (true)
        {
            Node *last = tail_.load(std::memory_order_acquire);      // 获取当前尾节点，第一次是哨兵节点
            Node *next = last->next.load(std::memory_order_acquire); // 获取尾节点的下一个节点

            // 检查 tail_ 是否在我们读取之后被其他线程改变了（一致性检查，防止ABA问题）
            if (last == tail_.load(std::memory_order_relaxed))
            {
                if (next == nullptr)
                {
                    // 这是正常情况：tail_ 指向的是真正的尾节点
                    // 尝试将新节点链接到尾部，确保只有一个线程能够成功链接到旧的尾部。如果失败（被其他线程抢先链接了，循环重新开始）
                    if (last->next.compare_exchange_weak(next, new_node, std::memory_order_release))
                    {
                        // 链接成功，现在尝试更新 tail_ 指针
                        // 即使下面这步失败也没关系，其他线程会帮忙推进 tail_
                        tail_.compare_exchange_weak(last, new_node, std::memory_order_release);
                        // 成功入队
                        return;
                    }
                }
                // 已经有其他线程在添加节点
                else
                {
                    // 帮助其他线程：tail_ 指针落后了，帮它更新到真正的尾节点
                    tail_.compare_exchange_weak(last, next, std::memory_order_release);
                }
            }
        }
    }

    /**
     * @brief [多消费者线程调用] 尝试从队列中取出一个元素
     * @return bool 如果返回false，表示队列为空
     */
    bool try_dequeue(T &value)
    {
        // CAS 循环：持续尝试，直到成功取出一个节点
        while (true)
        {
            Node *first = head_.load(std::memory_order_release);
            Node *last = tail_.load(std::memory_order_release);
            Node *next = first->next.load(std::memory_order_release);

            // 一致性检查，防止出现ABA问题
            if (first == head_.load(std::memory_order_release))
            {
                // 队列为空，或者 tail_ 指针落后了
                if (first == last)
                {
                    if (next == nullptr)
                    {
                        return false; // 队列确定为空
                    }
                    // tail_ 落后，帮助其他线程推进它
                    tail_.compare_exchange_weak(last, next, std::memory_order_release);
                }
                // 队列不为空
                else
                {
                    // 尝试移动 head_ 指针
                    // 我们要取出的值在 next 节点中（因为first是哨兵节点）
                    if (head_.compare_exchange_weak(first, next, std::memory_order_release))
                    {
                        value = std::move(next->data);

                        // ### UNSAFE ###
                        // 危险！这里是这个实现最不安全的地方。
                        // 在一个真实的 MPMC 队列中，你不能立即删除 'first' 节点，
                        // 因为其他线程可能仍然持有指向它的指针。
                        // 必须使用险象指针等技术来确保安全回收。
                        delete first;

                        return true;
                    }
                }
            }
        }
    }
};

#endif
```

#### MPMC 场景的 RingBuffer

可以参考[Facebook的folly库中的MPMCQueue](https://github.com/facebook/folly/blob/main/folly/MPMCQueue.h).

### 参考文章

- [MPMC队列](https://zaynpei.github.io/2025/10/19/lang/CPP/%E9%AB%98%E6%95%88%E7%BB%93%E6%9E%84/MPMC%E9%98%9F%E5%88%97/)
- [SPSC队列](https://zaynpei.github.io/2025/10/19/lang/CPP/%E9%AB%98%E6%95%88%E7%BB%93%E6%9E%84/SPSC%E9%98%9F%E5%88%97/)