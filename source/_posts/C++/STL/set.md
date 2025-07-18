---
title: STL-set
date: 2025-07-06
description: C++ 四种set
---

#### set

> 集合。存储指定的类型：`std::set<int> mySet;`.

#### 横向对比


|        **特性**         |        **`set`**         |  **`multiset`**  |    **`unordered_set`**     |  **`unordered_multiset`**  |
| :---------------------: | :----------------------: | :--------------: | :------------------------: | :------------------------: |
|      **底层结构**       | 红黑树（平衡二叉搜索树） |      红黑树      |    哈希表（Hash Table）    |           哈希表           |
|      **元素顺序**       |     有序（默认升序）     |       有序       |            无序            |            无序            |
|     **元素唯一性**      |           唯一           |      可重复      |            唯一            |           可重复           |
| **插入/查找时间复杂度** |         O(log n)         |     O(log n)     | O(1)（平均），O(n)（最坏） | O(1)（平均），O(n)（最坏） |
|    **迭代器稳定性**     |   稳定（除删除元素外）   |       稳定       |   不稳定（rehash时失效）   |           不稳定           |
|      **内存占用**       |    较低（树结构紧凑）    |       较低       |   较高（需预分配哈希桶）   |            较高            |
|      **适用场景**       |   需有序遍历或范围查询   | 需有序且允许重复 |     高频查找且无需顺序     |  高频插入/删除且允许重复   |