---
title: 平衡二叉树(AVL)
date: 2025-07-16
update: 2025-07-16
tags: [数据结构, 二叉树, C++, 树]
categories: 数据结构
---


如果插入二叉搜索树的元素在插入之前就已经有序，那么插入后的二叉搜索树会退化为链表。在这种情况下，所有操作的时间复杂度将从$O(log_2n)$劣化为$O(n)$ 。因此产生了平衡二叉树，能够实现在插入、删除时保持树的平衡，避免树退化为链表。平衡二叉树全称为：平衡二叉搜索树(`Balanced Binary Search Tree`).

### 特点：

1. **自平衡**：在插入或删除节点时，`AVL`树会通过旋转操作（如左旋、右旋、左右旋、右左旋）来保持树的平衡。
2. 如果一个树是`AVL`树，那么它的左右子树都是`AVL`树。
3. 树中任意一个节点的平衡因子绝对值不超过1。

   平衡因子：默认每个节点的平衡因子=`左子树高度-右子树高度`。（或者`右子树高度-左子树高度`）

### 实现

基本节点：

```cpp
typedef struct AVLNode {
    int data;
    int height{1}; // 节点高度：表示从当前节点到距离他最远的叶子节点的距离+1（叶子节点高度为1，空节点高度为0）
    AVLNode *left;
    AVLNode *right;
    AVLNode *parent; // 当前节点的双亲节点
    AVLNode(int data) : data(data), left(nullptr), right(nullptr) {}
    AVLNode(int data, AVLNode *left, AVLNode *right, AVLNode *parent) : AVLNode(data) {
        this->parent = parent;
        height = 1;
    };
} Node;
```

#### 插入

##### 递归插入

- 调用递归函数，传入**要插入的树的根节点`root`**和**要插入的值`data`**。因为此处`AVLNode`还用到了`parent`指针，所以还需要传入`parent`指针，方便新建节点时指定其`parent`指针的值。

- 如果`root==nullptr`说明是叶子节点。在该位置新建节点。存储要插入的值`data`,指定`height`为`1`(叶子节点高度为1)，同时指定`parent`指针为传入的`parent`参数。<mark>递归结束</mark>。

  > 因为此处新增了叶子节点，叶子节点高度指定为1，所以可以直接结束递归，不需要更新`root`(叶子节点)的高度。至于`root->parent`的高度，会在上层递归中更新。

- 判断要插入的值`data`和当前树的根节点`root->data`的大小关系。

  - `data < root->data`：递归插入到左子树`root->left`。插入到`root->left`后，需要判断`root`是否失衡。此处因为知晓插入到了`root->left`子树，所以只存在两种失衡情况：
    - 新增节点插入到了`root->left->left`子树上，符合`LL`情况，执行**右旋**。
    - 新增节点插入到了`root->left->right`子树上，符合`LR`情况，执行**左右双旋**。
  - `data > root->data`：递归插入到右子树`root->right`。插入到`root->right`后，需要判断`root`是否失衡。此处因为知晓插入到了`root->right`子树，所以只存在两种失衡情况：
    - 新增节点插入到了`root->right->right`子树上，符合`RR`情况，执行**左旋**。
    - 新增节点插入到了`root->right->left`子树上，符合`RL`情况，执行**右左双旋**。
  - `data == root->data`：提示要插入的值已经存在。**插入失败**。

- 插入并且旋转完成后，更新`root`节点的高度。（因为新增节点肯定插入了`root->left`或者`root->right`子树，可能导致`root`的高度发生变化）。<mark>递归结束</mark>。

##### 非递归插入

> 待补充

#### 删除

##### 递归删除

- 调用**删除函数**。传入根节点指针`root`和要删除的值`data`。

- 如果`root==nullptr`，说明没有找到`data`，删除失败。<mark>递归结束</mark>。

- 如果`root!=nullptr`，比较`root->data`和`data`的大小关系。

  - `root->data == data`，找到了要删除的节点。判断节点情况：

    - `root`是叶子节点：将root节点从树中删除。然后`delete root`.

    - `root`只有左子树，没有右子树：

      - 判断`root`是否是整个`AVL`树的根节点(`root->parent==nullptr`)：如果不是，则在执行下面一段。否则跳过下面一段。

        - 判断`root`是`root->parent`的左子树还是右子树：
        - 左子树：执行`root->parent->left = root->left`从树中删除`root`节点，然后<mark>更新`root->parent`节点的高度</mark>。
        - 右子树：执行`root->parent->right = root->left`从树中删除`root`节点，然后<mark>更新`root->parent`节点的高度</mark>。

      - 更新`root->left`的父节点指针`parent`。然后`delete root`.

        > 此处删除了`root`，但对`root->left`的平衡性没有影响。只是将`root->left`整体向上提高一层，取代`root`的位置。（因为`root->right==nullptr`）.
        >
        > 反倒是`root->parent`的平衡性可能受到影响，但是**`root->parent`的平衡性会在递归返回时被调整**。

    - `root`只有右子树，没有左子树：

      与上方逻辑类似

    - `root`的左右子树都存在：

      找到右子树中最小的值，覆盖`root->data`，然后再将右子树中最小的值(`minData`)删去：递归调用删除函数，传入`root->right`和`minData`。
  
  - `data < root->data`：
  
    - 要删除的`data`在`root`的左子树上。**递归调用删除函数**，传入左子树指针`root->left`和`data`。
    - 递归删除完成后，更新`root`的高度，
    - 然后平衡`root`节点（因为`root`的左子树删除了一个节点，高度可能发生变化，可能会影响`root`所在子树的平衡性）
  
  - `root->data < data`，要删除的`data`在`root`的右子树上。
  
    - **递归调用删除函数**，传入右子树指针`root->right`和`data`。
    - 递归删除完成后，更新`root`的高度，
    - 然后平衡`root`节点（因为`root`的右子树删除了一个节点，高度可能发生变化，可能会影响`root`所在子树的平衡性）

##### 非递归删除

> 待补充

#### 查询

##### 递归查询

- 调用递归查询函数，传入树的根节点`root`和要查询的值`data`。
- 如果`root==nullptr`，说明递归到了叶子节点下的空节点，或者整个树为空，即：没有找到目标值。返回`false`，递归结束。
  - 如果`root->data==data`，找到目标值，返回`true`，递归结束。
  - 如果`root->data > data`，递归左子树。返回左子树的递归结果。
  - 如果`root->data < data`，递归右子树。返回右子树的递归结果。

##### 非递归查询

待补充

#### 核心算法：旋转操作

##### 左旋

![左旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222714402.png)

##### 右旋

![右旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222747055.png)

##### 左右双旋

先左旋，再右旋

![左右双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721223004318.png)

##### 右左双旋

先右旋，再左旋

![右左双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222927312.png)