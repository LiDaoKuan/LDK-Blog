---
title: C++ RingBuffer实现
date: 2026-02-21
updated: 2026-02-21
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
        const auto current_head = head_.load(std::memory_order_release);

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

### 
