---
title: 二叉搜索树
date: 2025-07-10
updated: 2025-07-11
tags: [数据结构, 二叉树, Cpp, 树]
categories: 数据结构
---

### 特点

1. 非空左子树的所有结点的值小于其根结点的值。
2. 非空右子树的所有结点的值大于其根结点的值。
3. 左、右子树都是二叉搜索树。

### 实现

#### 主要操作

##### 查询：

实现思路：

- 递归：调用递归方法，传入要查询的树的根节点和要查询的值，判断根节点值大小，然后递归查询。
- 非递归：通过while循环，判断当前指针指向的节点值是否满足条件或者当前指针是否为空。然后根据情况令指针指向当前节点的左子节点或者右子节点。如果当前节点变为空，说明没有找到目标值。

##### 插入：

- 递归：调用递归方法，传入要插入的值和树的根节点。如果当前根节点值小于插入的值，递归调用插入方法，传入右子树的根节点。如果当前根节点值大于插入的值，递归调用插入方法，传入左子树的根节点。<mark>如果相等，报错（二叉搜索树不允许存在重复的值）</mark>。
- 非递归：通过while循环，通过判断插入值的大小，不断改变遍历的指针指向的节点，同时用另一个指针记录上一个遍历过的节点（方便查找到叶子节点时向前看一个节点，便于操作）。

##### 删除：

首先找到要删除的节点，然后判断情况。主要分为三种情况：

- 左子树为空，只有右子树：直接将右子树向上提升一级（用右子树替换要删除的节点，然乎释放要删除的节点的空间(`new`出来的当然要`delete`)）。
- 右子树为空，只有左子树：直接将左子树向上提升一级（思路同上）。
- **左右子树都不为空**：将右子树中值最小的节点和要删除的节点交换，然后删除目标节点（此时目标节点已经在原右子树最小元素的位置上，但该位置可能是一个分叉节点，所以应该递归调用删除方法进行删除）。

C++实现：

```cpp
#include <iostream>
#include <queue>

struct Node {
    int data;
    Node *left;
    Node *right;
    Node(int data) {
        this->data = data;
        left = nullptr;
        right = nullptr;
    }
    Node(int data, Node *left, Node *right) {
        this->data = data;
        this->left = left;
        this->right = right;
    }
};

// 二叉搜索树
class BST {
private:
    Node *root;

public:
    BST() {
        root = nullptr;
    }
    BST(int root_data) {
        root = new Node(root_data);
    }

    Node *get_root() {
        return root;
    }

    // 递归方式插入
    void insert_recursion(int data) {
        if (root == nullptr) {
            root = new Node(data);
            return;
        }
        recursion_insert(root, data); // 调用递归函数
    }

    // 非递归方式插入
    void insert_unrecursion(int data) {
        if (root == nullptr) {
            root = new Node(data);
            return;
        }
        Node *current = root;
        Node *parent; // 记录上一个遍历过的节点
        while (current != nullptr) {
            parent = current;
            if (current->data > data) {
                current = current->left;
            } else if (current->data < data) {
                current = current->right;
            } else {
                std::cout << "insert error: data is already exist" << std::endl;
                return;
            }
        }
        if (parent->data > data) {
            parent->left = new Node(data);
        } else { // while循环中已经判断过元素相等的情况，这里不用再判断
            parent->right = new Node(data);
        }
    }

    Node *search(int data) {
        if (root == nullptr) {
            return nullptr;
        }
        Node *parent = nullptr;
        Node *current = root;
        while (current != nullptr) {
            parent = current;
            if (current->data == data) {
                return current;
            } else if (current->data > data) {
                current = current->left;
            } else {
                current = current->right;
            }
        }
        return nullptr;
    }

    void delete_node(int data) {
        if (root == nullptr) {
            printf("delete failed: tree has zero node");
            return;
        }
        delNode(root, data);
    }

    ~BST() {
        destroyTree(root);
    }

private:
    void recursion_insert(Node *&node, int data) {
        if (node == nullptr) {
            node = new Node(data);
            return;
        }
        if (data > node->data) {
            recursion_insert(node->right, data);
        } else if (data < node->data) {
            recursion_insert(node->left, data);
        } else {
            std::cout << "insert error: data is already exist" << std::endl;
        }
    }

    void delNode(Node *&root, int data) {
        if (root == nullptr) {
            return;
        } else if (root->data < data) {
            delNode(root->right, data);
        } else if (root->data > data) {
            delNode(root->left, data);
        } else {
            // root节点就是要删除的节点
            if (root->left == nullptr) {
                Node *temp = root;
                root = root->right;
                printf("deleted node: %d\n", temp->data);
                delete temp;
                return;
            }
            if (root->right == nullptr) {
                Node *temp = root;
                root = root->left;
                printf("deleted node: %d\n", temp->data);
                delete temp;
                return;
            }
            /**
             * 左右子树都不为空：
             *      将右子树中的最小节点与要删除的节点交换，然后删除交换后的节点。
             *      删除时，考虑原右子树的最小节点可能是分支节点，所以应该递归调用删除方法进行删除。
             */
            Node *current = root->right;
            while (current != nullptr && current->left != nullptr) {
                // 找到符合条件的右子树最小节点
                current = current->left;
            }
            /**
             * 此处不必实现两数交换，如果只是实现删除，可以直接拿current->data覆盖root->data
             * 但是考虑到某些时候需要deleteNode方法返回被删除的元素的值，此处进行了交换处理，便于更改。
             */
            int temp = current->data;
            current->data = root->data;
            root->data = temp;
            delNode(root->right, current->data); // 删除右子树中被交换后的节点
        }
    }

    void destroyTree(Node *root) {
        if (root == nullptr) {
            return;
        }
        if (root->left != nullptr) {
            destroyTree(root->left);
        }
        if (root->right != nullptr) {
            destroyTree(root->right);
        }
        std::cout << "destroyed node: " << root->data << std::endl;
        delete root;
    }
};

void inorderPrintTree(Node *root) {
    if (root == nullptr) {
        return;
    }
    inorderPrintTree(root->left);
    std::cout << root->data << " ";
    inorderPrintTree(root->right);
}

int main() {
    int arr[] = {5, 3, 2, 4, 7, 6, 8};
    int size = sizeof(arr) / sizeof(arr[0]);

    BST bst = BST();

    for (int i = 0; i < size; ++i) {
        bst.insert_unrecursion(arr[i]);
    }
    inorderPrintTree(bst.get_root());
    printf("\n");
    for (int i = 0; i < size; ++i) {
        if (bst.search(arr[i])) {
            printf("find %d\n", arr[i]);
        } else {
            printf("not found %d\n", arr[i]);
        }
    }

    for (int i = 0; i < size; ++i) {
        bst.delete_node(arr[i]);
    }

    return 0;
}
```

正确输出：

```cpp
2 3 4 5 6 7 8 
find 5
find 3
find 2
find 4
find 7
find 6
find 8
deleted node: 5
deleted node: 3
deleted node: 2
deleted node: 4
deleted node: 7
deleted node: 6
deleted node: 8
```

