---
title: shared_lock
tags: [Cpp, 并法, 原子操作]
categories: Cpp
date: 2025-07-06
---

### shared_lock

专门用于管理 `std::shared_timed_mutex` 或 `std::shared_mutex` 的共享锁。它简化了获取和释放共享锁的操作，并提供了一些附加功能，比如延迟锁定、超时锁定等。

成员函数：

- `shared_lock()`: 创建一个未锁定的`shared_lock`。

- `shared_lock(mutex_type& m)`: 

  创建一个`shared_lock` 并尝试锁定给定的`mutex_type`（`std::shared_timed_mutex` 或 `std::shared_mutex`）。如果锁定失败，则抛出异常。

- `shared_lock(mutex_type& m, std::defer_lock_t t)`: 

  创建一个未锁定的 `shared_lock`，但关联到给定的`mutex_type`。

- `shared_lock(mutex_type& m, std::try_to_lock_t t)`: 

  尝试锁定给定的 `mutex_type`，如果成功则锁定，否则创建一个未锁定的`shared_lock`。

- `shared_lock(mutex_type& m, const std::chrono::time_point<Clock, Duration>& abs_time)`:

  尝试在给定的绝对时间点之前锁定给定的`mutex_type`。如果成功则锁定，否则创建一个未锁定的`shared_lock`。

- `shared_lock(mutex_type& m, const std::chrono::duration<Rep, Period>& rel_time)`: 

  尝试在给定的相对时间段内锁定给定的 `mutex_type`。如果成功则锁定，否则创建一个未锁定的`shared_lock`。

- `lock()`: 锁定关联的互斥量（如果尚未锁定）。

- `try_lock()`: 尝试锁定关联的互斥量，如果成功则返回`true`，否则返回`false`。

- `try_lock_for(duration)`: 尝试在指定的时间段内锁定关联的互斥量，如果成功则返回`true`，否则返回`false`。

- `try_lock_until(time_point)`: 尝试在给定的时间点之前锁定关联的互斥量，如果成功则返回`true`，否则返回`false`。

- `unlock()`: 释放锁（如果持有）。

- `owns_lock()`: 检查 `shared_lock` 是否持有锁。

- `operator bool()`: 检查 `shared_lock` 是否持有锁（返回 `owns_lock()` 的结果）。