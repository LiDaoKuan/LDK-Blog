---
title: 满二叉树
date: 2025-07-13
updated: 2025-07-14
tags: [数据结构, 二叉树, Cpp, 树]
categories: 数据结构
---

### 基本概念：

满二叉树：**层数(高度)**为`H`，总节点数为$2^H-1$的二叉树。（根节点在第`1`层，所有叶子节点都在第`H`层）。

> 此处认为`满二叉树 == 完美二叉树`。
>
> 有些地方存在另一种分类方法：完美(`prefect`)二叉树、完满(`full`)二叉树、完全(`complete`)二叉树。具体概念与上述满二叉树概念也有所区别，此处不做讨论。
>
> > 本文所讨论的满二叉树对应上面的完美(`prefect`)二叉树，而不对应完满(`full`)二叉树。
> >
> > 而上述完满(`full`)二叉树实际对应王道考研书中的**正则二叉树**。

### 特点：

- 第`i`层一定有$2^{i-1}$个节点。（根节点在第`1`层）
- 前`i`层（`1 ~ i`层）节点数之和为$2^i-1$。

### 由前序遍历构建满二叉树

给定一个满二叉树的**前序遍历**数组，要求由该数组构建目标满二叉树，返回构建完成的满二叉树的根。然后输出该满二叉树的**中序遍历**。

##### C++实现：

**一般来说，构造二叉树不能只用前序遍历**，但这里给出了一个额外的条件，即该二叉树是满二叉树。我们可以利用这个额外的条件。

对满二叉树来说：前序遍历中根之后的元素数量（假设为`n`）应该是偶数（2 * 一个子树中的节点数，因为它是满二叉树）。根据前序遍历的特点：对同一个根节点，它的左子树的前序遍历一定在它的右子树的前序遍历之前。那么我们就可以找到左子树的前序遍历和右子树的前序遍历。

```cpp
#include <iostream>

struct Node {
    int data;
    Node *left, *right;
    Node(int val) {
        data = val;
        left = nullptr;
        right = nullptr;
    }
};

/**
 * @brief 由前序遍历构建满二叉树
 * @param preOrder 要构建的满二叉树的前序遍历
 * @param length 前序遍历的长度
 * @return 构建好的满二叉树的根节点
 */
Node *creat_full_binary_tree(int *preOrder, int length) {
    if (length == 0) {
        return nullptr;
    }
    Node *root = new Node(preOrder[0]);
    root->left = creat_full_binary_tree(preOrder + 1, (length - 1) / 2);
    root->right = creat_full_binary_tree(preOrder + 1 + (length - 1) / 2, (length - 1) / 2);
    return root;
}

void printInOrder(Node *root) {
    if (root == nullptr) {
        return;
    }
    printInOrder(root->left);
    std::cout << root->data << " ";
    printInOrder(root->right);
}

void destroy_binary_tree(Node *root) {
    if (root == nullptr) {
        return;
    }
    destroy_binary_tree(root->left);
    destroy_binary_tree(root->right);
    std::cout << "deleted: " << root->data << std::endl;
    delete root;
}

int main() {
    int arr[] = {1, 2, 4, 5, 3, 6, 7};
    int size = sizeof(arr) / sizeof(arr[0]);

    Node *root = creat_full_binary_tree(arr, size);
    printInOrder(root);
    destroy_binary_tree(root);

    return 0;
}
```

正确输出：

```cpp
4 2 5 1 6 3 7
```

