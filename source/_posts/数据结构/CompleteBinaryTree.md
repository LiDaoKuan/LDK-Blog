---
title: 完全二叉树
date: 2025-07-09
update: 2025-07-11
tags: [数据结构, 二叉树, C++, 树]
categories: 数据结构
---

## 完全二叉树

### 基本概念

完全二叉树：基于二叉树，要求除了最下层外，其余各层都是满节点。<mark>并且，最后一层的节点必须尽可能向左放</mark>。

例：下面所有二叉树都<mark>不是</mark>完全二叉树：

<img src="https://image-1258881983.cos.ap-beijing.myqcloud.com/image2a5cac1b30c8c3c2a29f6b9903c5dfcf.png" alt="例1" style="zoom:67%;" />

<img src="https://image-1258881983.cos.ap-beijing.myqcloud.com/image20250709221221457.png" alt="例2" style="zoom:67%;" />

<img src="https://image-1258881983.cos.ap-beijing.myqcloud.com/imageb7853ade89f82f3208931148ebeca351.png" alt="例3" style="zoom:67%;" />

### 特征

- 叶子节点之可能在最下面的**两层**出现
- 对任意结点，若其`右分支下的子孙最大层次为L`，则其`左分支下的子孙的最大层次必为L或L+1`。
- 所有节点中，<mark>最多只有一个节点度为1</mark>（只有一个孩子）。

### 实现

方便起见，<mark>完全二叉树一般用数组实现</mark>而不用链表。

<img src="https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250709232438563.png" alt="例图" style="zoom:67%;" />

对于用数组存储的完全二叉树，有以下特点：（**下标从0开始**）（根节点层数为1）

1. 如果一个节点在数组中下标为`i`，则它在树中的层数为<mark> $\left\lfloor log_2{(i+1)} \right\rfloor$ </mark>（向下取整），它的左子节点在数组中对应的下标为：$2i+1$（如果存在），右子节点在数组中对应的下标为$2i+2$（如果存在）。
2. 如果完全二叉树总共有`n`个节点，那么树高：<mark> $h=\left \lfloor log_2{n} \right \rfloor+1$ </mark>（向下取整再+1。注意：**不能直接向上取整，两者不相等**）。
3. 如果完全二叉树树高`h`，那么这个完全二叉树最多拥有$2^h-1$个节点。

如果**下标从1开始**，那么第一条中，左子节点对应下标改为：<mark>$2i$</mark>，右子节点对应下标改为：<mark>$2i+1$</mark>。（相比于下标从0开始，直接-1）

#### 用数组构建完全二叉树

>  给定一个数组，用层序便利构建二叉树。然后输出它的中序遍历。
>
> 例如：<img src="https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250710180412848.png" alt="image-20250710180412848" style="zoom: 67%;" />

C++实现：

```cpp
#include <iostream>
#include <queue>
/*
 * 两种方法：
 * 1. 递归
 * 2. 队列
 */

struct Node
{
	int data;
	Node *left;
	Node *right;
	Node() {}
	Node(int data, Node *left, Node *right)
	{
		this->data = data;
		this->left = left;
		this->right = right;
	}

	virtual void test()
	{
		std::cout << "test" << std::endl;
	}
};

void inorderPrintTree(Node *root)
{
	if (root == nullptr)
	{
		return;
	}
	inorderPrintTree(root->left);
	std::cout << root->data << " ";
	inorderPrintTree(root->right);
}

void destroyTree(Node *root)
{
	if (root == nullptr)
	{
		return;
	}
	if (root->left != nullptr)
	{
		destroyTree(root->left);
	}
	if (root->right != nullptr)
	{
		destroyTree(root->right);
	}
	std::cout << "destroyed node: " << root->data << std::endl;
	delete root;
}

/**
 * 非递归构建：使用栈
 */
void unRecursion()
{
	int arr[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
	int size = sizeof(arr) / sizeof(arr[0]);

	Node *root = new Node(arr[0], nullptr, nullptr);
	Node *point = root;

	std::queue<Node *> que;
	que.push(point);
	int index = 1;

	// 构建完全二叉树
	while (index < size)
	{
		point = que.front();
		que.pop();

		if (index < size)
		{
			point->left = new Node(arr[index++], nullptr, nullptr);
			que.push(point->left);
		}
		if (index < size)
		{
			point->right = new Node(arr[index++], nullptr, nullptr);
			que.push(point->right);
		}
	}

	// 中序遍历
	inorderPrintTree(root);

	destroyTree(root);
}

/**
 * 递归构建
 */
void recursion(int arr[], int i, int n, Node *&root)
{
	if (i < n)
	{
		root = new Node(arr[i], nullptr, nullptr);
		recursion(arr, i * 2 + 1, n, root->left);
		recursion(arr, i * 2 + 2, n, root->right);
		return;
	}
	root = nullptr;
}

int main()
{
	// unRecursion();				// 非递归

	/*
	 * 递归
	*/
	int arr[] = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
	int size = sizeof(arr) / sizeof(arr[0]);

	Node *root = nullptr;

	recursion(arr, 0, size, root);

	inorderPrintTree(root);

	destroyTree(root);

	return 0;
}
```

非递归方法构建完全二叉树的思路：

**使用队列保存已经构建好的部分的层序遍历顺序，然后从队列中取出元素，将该元素的左右子节点（如果存在）放入队列（也就是将下一层的元素放入队列），直至队列为空**。

递归方法构建思路：

**传入要构建的数组，和当前要构造的节点在数组中的下标。根据根节点和左右子节点在数组中的下标之间的关系，递归构建左右子节点**。

## 完全N叉树

与完全二叉树类似：

- 除了最后一层，其余各层已经满节点。
- 最后一层的所有节点尽可能向左边放。

### 由后续遍历构建完全N叉树

给定一个大小为**M**的数组`arr[]` ，其中包含**完整 N 叉树**的后序遍历，任务是生成 N 叉树并打印其**前序遍历**。

```cpp
#include <iostream>


```

