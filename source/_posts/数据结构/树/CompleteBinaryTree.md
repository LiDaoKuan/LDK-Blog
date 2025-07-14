---
title: 完全二叉树
date: 2025-07-09
update: 2025-07-13
tags: [数据结构, 二叉树, C++, 树, 完全N叉树]
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

##### 非递归方法构建完全二叉树的思路：

**使用队列保存已经构建好的部分的层序遍历顺序。**

- 首先，构建根节点，然后根节点进入队列。
- 循环：
  - 如果队列不为空，从队列中取出节点元素。
  - 构建该节点的左右子节点（如果存在的话）。并且将构建好的左子节点和右子节点分别入队。也就是将下一层的元素放入队列。
  - 如果队列为空，跳出循环。

##### 递归方法构建思路：

- 传入节点数组。并且传入当前要构建的节点在数组中的下标。
- 根据数组中的元素值构建当前节点。
- 判断左右子节点：(假设完全二叉树根节点对应数组下标为1)
  - 左子节点(`2i+1`)存在：递归调用函数进行构建
  - 右子节点(`2i+2`)存在：递归调用函数进行构建
- 返回当前构建好的节点的指针，便于将不同节点连接在一起。

## 完全N叉树

与完全二叉树类似：

- 除了最后一层，其余各层已经满节点。
- 最后一层的所有节点尽可能向左边放。

### 由后续遍历构建完全N叉树

给定一个大小为**M**的数组`arr[]` ，其中包含**完整 N 叉树**的后序遍历，任务是生成 N 叉树并打印其**前序遍历**。

例图：

![完全3叉树](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250713220657917.png)

C++实现：

```cpp
#include <iostream>
#include <cmath>

/*
    根据后续遍历生成完全n叉树，然后输出它的前序遍历
*/

template <class T>
class Node {
public:
    Node(T data);

    // 获取左边第一个子节点
    Node *get_first_child() {
        return first_child;
    }

    // 获取右边下一个兄弟节点
    Node *get_next_sibling() {
        return next_sibling;
    }

    void append_add_sibling(Node *sibling) {
        if (next_sibling == nullptr) {
            this->next_sibling = sibling;
        } else {
            next_sibling->append_add_sibling(sibling);
        }
    }

    void add_child(Node *child) {
        if (first_child == nullptr) {
            first_child = child;
        } else {
            first_child->append_add_sibling(child);
        }
    }

    T get_data() {
        return this->data;
    }

private:
    T data;
    Node *first_child;
    Node *next_sibling;
};

template <class T>
Node<T>::Node(T data) {
    this->data = data;
    first_child = nullptr;
    next_sibling = nullptr;
}

/**
 * @brief 由后续遍历构造完全N叉树
 * @param post_order_arr 后续遍历数组
 * @param size 数组长度
 * @param k 等同于N叉树的N
 * @return 构造的k叉树的根节点指针
 */
template <typename T>
Node<T> *construct_n_binary_tree(T *post_order_arr, int size, int k) {
    // 构造当前树的根节点
    Node<T> *root = new Node<T>(post_order_arr[size - 1]);
    if (size == 1) {
        // 说明该节点(rot)是叶子节点
        return root;
    }
    // 求树高。根据完全N叉树的特性推导而来
    int height_of_tree = ceil(log2(size * (k - 1) + 1) / log2(k)) - 1; // 向上取整
    // 最后一层节点数
    int nodes_in_last_level = size - (pow(k, height_of_tree) - 1) / (k - 1);

    int tracker = 0;
    while (tracker != (size - 1)) {
        /**
         * pow(k, height_of_tree - 1)： 树高 height_of_tree - 1 的情况下，理论最后一层满节点数量（根节点在第0层）
         * nodes_in_last_level： 实际最后一层节点数量
         */
        int last_level_nodes = (pow(k, height_of_tree - 1) > nodes_in_last_level) ? nodes_in_last_level : pow(k, height_of_tree - 1);
        /**
         * （从左到右）以root的孩子为根节点的子树的节点数量
         * (pow(k, height_of_tree - 1) - 1) / (k - 1): 树高 height_of_tree - 2 情况下，满k叉树的节点数量（注意：树高度+1==总层数）
         * last_level_nodes：
         */
        int nodes_in_next_subtree = ((pow(k, height_of_tree - 1) - 1) / (k - 1)) + last_level_nodes;

        root->add_child(construct_n_binary_tree(post_order_arr + tracker, nodes_in_next_subtree, k));
        tracker += nodes_in_next_subtree;        // 已经构建的子树的节点数之和
        nodes_in_last_level -= last_level_nodes; // 去掉已经构建的子树的最后一层的节点
    }
    return root;
}

// 前序遍历n叉树
template <typename T>
void printPreOrder(Node<T> *root) {
    if (root == nullptr) {
        return;
    }
    std::cout << root->get_data() << " ";
    printPreOrder(root->get_first_child()); // 递归遍历root的左边第一个孩子时，也会将它的兄弟(root的第二, 第三,...第k个孩子)一块遍历
    printPreOrder(root->get_next_sibling());
}

// 释放空间
template <typename T>
void destroy_n_binary_tree(Node<T> *root) {
    if (root == nullptr) {
        return;
    }
    if (root->get_next_sibling() != nullptr) {
        destroy_n_binary_tree(root->get_next_sibling());
    }
    if (root->get_first_child() != nullptr) {
        destroy_n_binary_tree(root->get_first_child());
    }
    std::cout << "deleted: " << root->get_data() << std::endl;
    delete root;
}

int main() {
    int arr[] = {5, 6, 7, 2, 8, 9, 3, 4, 1};
    int size = sizeof(arr) / sizeof(arr[0]);

    Node<int> *root = construct_n_binary_tree(arr, size, 3);

    printPreOrder(root);

    destroy_n_binary_tree(root);

    return 0;
}
```

正确输出：

```cpp
1 2 5 6 7 3 8 9 4
```

##### 由后续遍历构建完全N叉树的思路

核心思路：递归。**难点：如何求得根节点的各个子节点所在子树的节点总数**。

1. 传入要构建的树的后续遍历，以及总节点数。还有树的分叉数：N。
2. 识别根节点。同时求得树高（推导数学公式）
3. 循环：
   1. 计算根节点的第`i`个孩子所在的子树所拥有的节点数（数学方法+逻辑推理）（$1\leq i\leq k$）（<mark>此处为了便于理解引入变量`i`，实际实现时循环中并不存在变量`i`</mark>）
   2. 构建根节点的第`i`个孩子所在的子树（<mark>递归</mark>。传入后续遍历（通过原数组偏移量和节点数））。构建完成后挂载到根节点上。
   3. 记录已经构建完成的子树的节点数之和（循环累加）
   4. 如果：已经构建完成的节点树之和<mark>等于</mark>总节点数-1，（如果构建成功只能是等于，不能是大于），那么该树构建完成。
4. 返回构建的根节点。
