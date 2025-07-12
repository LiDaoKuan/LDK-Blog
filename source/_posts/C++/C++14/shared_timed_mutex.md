---
title: shared_timed_mutex
date: 2025-07-06
---

### shared_timed_mutex

共享超时互斥锁（具备超时功能的读写锁）

成员函数：

- `lock_shared()`: 获取==共享锁==，如果当前有独占锁，则阻塞。
- `try_lock_shared()`: 尝试获取共享锁，如果成功则返回`true`，否则返回`false`，不阻塞。
- `try_lock_shared_for(duration)`: 尝试在指定的时间段内获取共享锁，如果成功则返回`true`，否则返回`false`。
- `lock()`: 获取==独占锁==，如果当前有共享锁或独占锁，则阻塞。
- `try_lock()`: 尝试获取独占锁，如果成功则返回`true`，否则返回`false`，不阻塞。
- `try_lock_for(duration)`: 尝试在指定的时间段内获取独占锁，如果成功则返回`true`，否则返回`false`。
- `unlock()`: 释放当前持有的锁（无论是共享锁还是独占锁）。