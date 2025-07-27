---
title: 平衡二叉树(AVL)
date: 2025-07-12
updated: 2025-07-16
tags: [数据结构, 二叉树, C++, 树]
categories: 数据结构
---


如果插入二叉搜索树的元素在插入之前就已经有序，那么插入后的二叉搜索树会退化为链表。在这种情况下，所有操作的时间复杂度将从 $O(log_2n)$ 劣化为 $O(n)$ 。因此产生了平衡二叉树，能够实现在插入、删除时保持树的平衡，避免树退化为链表。平衡二叉树全称为：平衡二叉搜索树(`Balanced Binary Search Tree`).

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

###### 逻辑

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

###### 代码实现

```cpp
// 插入(递归实现)
Node *insert_recursion(Node *root, Node *parent, int data) {
    if (root == nullptr) {
        // 新插入一个节点。新插入的节点一定是叶子节点，所以该节点的高度为1（类内初始化）
        return new Node(data, nullptr, nullptr, parent);
    } else if (root->data > data) {
        root->left = insert_recursion(root->left, root, data);
        // 插入后判断root是否失衡。因为插入的是root->left，所以只需要考虑root左边过高的情况
        if (abs(get_balance(root)) == 2) { // root节点失衡
            if (root->left != nullptr && data < root->left->data) {
                // 执行右单旋操作。
                root = right_rotate(root);
            } else {
                // 执行左右旋操作。
                root = left_right_rotate(root);
            }
        }
    } else if (root->data < data) {
        root->right = insert_recursion(root->right, root, data);
        // 判断root是否失衡
        if (abs(get_balance(root)) == 2) {
            if (root->right != nullptr && data > root->right->data) {
                // 执行左单旋。
                root = left_rotate(root);
            } else {
                // 执行右左旋。
                root = right_left_rotate(root);
            }
        }
    } else {
        printf("ERROR! data already exist.\n");
    }
    // 无论插入情况如何，都要在插入后更新root节点的节点高度
    update_height(root);
    return root;
}
```



##### 非递归插入

> 待补充

#### 删除

##### 递归删除

###### 逻辑

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

###### 代码实现

```cpp
// 删除(递归实现)
Node *delete_recursion(Node *root, int data) {
    if (root != nullptr) {
        if (root->data == data) { // 找到要删除的节点
            printf("delete: %d\n", data);
            if (root->right == nullptr && root->left != nullptr) { // root只有左孩子，没有右孩子
                if (root->parent != nullptr) { // 考虑root是否是整个树的根节点
                    if (root->data > root->parent->data) { // root是root->parent的右孩子
                        root->parent->right = root->left;
                    } else { // root是root->parent的左孩子
                        root->parent->left = root->left;
                    }
                    update_height(root->parent); // 因为删除了root节点，所以要更新root->parent节点的高度
                }
                root->left->parent = root->parent; // 更新父节点指针
                // 执行平衡操作? 似乎多余? root->left本来就是平衡的，只是取代了root，对root->left的平衡性没有影响。
                // root->left = balance(root->left);
                Node *temp = root->left;
                delete root;
                root = temp; // root节点从树中删除，root->left取代root
            } else if (root->left == nullptr && root->right != nullptr) { // root只有右孩子，没有左孩子
                if (root->parent != nullptr) {
                    if (root->data > root->parent->data) {
                        root->parent->right = root->right;
                    } else {
                        root->parent->left = root->right;
                    }
                    update_height(root->parent);
                }
                root->right->parent = root->parent;
                // root->right = balance(root->right);
                Node *temp = root->right;
                delete root;
                root = temp;
            } else if (root->left != nullptr && root->right != nullptr) { // 左右孩子都有
                Node *temp = root->right;
                while (temp->left != nullptr) { // 找到root的右子树中的最小节点
                    temp = temp->left;
                }
                int val = temp->data;
                root->right = delete_recursion(root->right, val);
                root->data = val;
                update_height(root); // root的右子树发生了变动，更新root的高度
                root = balance(root);
            } else { // root是叶子节点
                if (root->parent != nullptr) { // root存在父节点
                    if (root->parent->data < root->data) { // root是其父亲节点的右孩子
                        root->parent->right = nullptr; // 删去root节点
                    } else { // root是其父亲节点的左孩子
                        root->parent->left = nullptr;
                    }
                    update_height(root->parent);
                }
                delete root;
                root = nullptr;
            }

        } else if (data < root->data) {
            root->left = delete_recursion(root->left, data);
            update_height(root);
            root = balance(root);
        } else {
            root->right = delete_recursion(root->right, data);
            update_height(root);
            root = balance(root);
        }
    } else {
        printf("Key to be deleted could not be found.\n");
    }

    return root;
}

// 平衡root节点
Node *balance(Node *root) {
    int balance_factor = get_balance(root);
    if (abs(balance_factor) == 2) {
        if (balance_factor < 0) { // root节点的右子树高度 > 左子树高度
            if (get_balance(root->right) == 1) { // root->right的左子树高度 > 右子树高度，root节点符合RL失衡，执行左右双旋
                root = right_left_rotate(root);
            } else { // root->right的右子树高度 > 左子树高度，root节点符合RR失衡，执行左单旋
                root = left_rotate(root);
            }
        } else { // root节点的右子树高度 < 左子树高度
            if (get_balance(root->left) == 1) { // root->left的左子树高度 > 右子树高度，root节点符合LL失衡，执行右单旋
                root = right_rotate(root);
            } else { // root->right的右子树高度 > 左子树高度，root节点符合LR失衡，执行右左双旋
                root = left_right_rotate(root);
            }
        }
    }
    return root;
}
```



##### 非递归删除

> 待补充

#### 查询

##### 递归查询

###### 逻辑

- 调用递归查询函数，传入树的根节点`root`和要查询的值`data`。
- 如果`root==nullptr`，说明递归到了叶子节点下的空节点，或者整个树为空，即：没有找到目标值。返回`false`，递归结束。
  - 如果`root->data==data`，找到目标值，返回`true`，递归结束。
  - 如果`root->data > data`，递归左子树。返回左子树的递归结果。
  - 如果`root->data < data`，递归右子树。返回右子树的递归结果。

###### 代码实现：

```cpp
// 查询(递归实现)
bool search(const Node *root, const int &data) {
    if (root == nullptr) {
        return false;
    }
    if (root->data == data) {
        return true;
    } else if (data < root->data) {
        return search(root->left, data);
    } else {
        return search(root->right, data);
    }
}
```



##### 非递归查询

待补充

#### 核心算法：旋转操作

##### 左旋

![左旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222714402.png)

C++实现：

```cpp
/**
 * @brief root节点失衡，对root和root->right进行左旋操作。
 * @param root 失衡节点
 */
Node *left_rotate(Node *root) {
    Node *childR = root->right;
    Node *childRL = childR->left;

    root->right = childRL;
    childR->left = root;

    if (childRL != nullptr) {
        childRL->parent = root;
    }
    childR->parent = root->parent;
    root->parent = childR;
    if (childR->parent != nullptr) {
        if (childR->data < childR->parent->data) {
            childR->parent->left = childR;
        } else {
            childR->parent->right = childR;
        }
    }

    root = childR;
    update_height(root->left);
    update_height(root->right);
    update_height(root);
    update_height(root->parent);

    return root;
}
```



##### 右旋

![右旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222747055.png)

C++实现：

```cpp
/**
 * @brief root节点失衡，对root和root->left执行右旋操作。
 * @param root 失衡节点
 */
Node *right_rotate(Node *root) {
    Node *childL = root->left;
    Node *childLR = childL->right;

    /**
     * 如果只使用了height属性，没有使用parent属性，则只需要 下面两行语句 和 root=Lchild 以及 四个update_height()即可完成旋转。
     * 如果使用了parent则需要加入剩余的代码。
     */
    root->left = childLR;
    childL->right = root;

    if (childLR != nullptr) {
        // 说明原root->left->right非空，需要更新它的父节点指针。
        childLR->parent = root;
    }
    childL->parent = root->parent;
    root->parent = childL;
    if (childL->parent != nullptr) {
        if (root->data < childL->parent->data) {
            // 原root节点挂载在root->parent的左边，旋转后将新树也挂载在左边
            childL->parent->left = childL;
        } else {
            // 否则挂载到右边
            childL->parent->right = childL;
        }
    }

    root = childL;
    update_height(root->left);
    update_height(root->right);
    update_height(root);
    update_height(root->parent); // 注意此处需要更新root->parent的高度，因为root->parent的其中一个子树(也就是root)高度改变，所以会影响root->parent的高度

    return root;
}
```



##### 左右双旋

先左旋，再右旋

![左右双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721223004318.png)

C++实现：

```cpp
/**
 * @brief 左右旋
 */
Node *left_right_rotate(Node *root) {
    // 先对root->left和root->left->right进行左单旋
    root->left = left_rotate(root->left);
    // 在对root和root->left进行右单旋
    return right_rotate(root);
}
```



##### 右左双旋

先右旋，再左旋

![右左双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250721222927312.png)

C++实现：

```cpp
/**
 * @brief 右左旋
 */
Node *right_left_rotate(Node *root) {
    // 先对root->right和root->right->left进行右单旋
    root->right = right_rotate(root->right);
    // 再对root和root->right进行左单旋
    return left_rotate(root);
}
```

#### 完整代码实现：

```cpp
#include <iostream>
#include <queue>
#include <iomanip>
#include <cstring>
using namespace std;

class AVLTree {
public:
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

    AVLTree() : root(nullptr) {}

    AVLTree(int data) {
        root = new Node(data);
    }

    ~AVLTree() {
        delete_tree(root);
    }

    void insert_node(int data) {
        root = insert_recursion(root, nullptr, data); // 直接调用递归函数进行插入

        /**
         * 待补充: 非递归的插入方法
         */
    }

    void delete_node(int data) {
        root = delete_recursion(root, data); // 调用递归的删除方法

        /**
         * 待补充: 非递归的删除方法
         */
    }

    bool search(int data) {
        return search(root, data); // 调用递归的查询方法

        /**
         * 待补充: 非递归的查询方法
         */
    }

    Node *get_root() {
        return this->root;
    }

private:
    Node *root;

    // 插入(递归实现)
    Node *insert_recursion(Node *root, Node *parent, int data) {
        if (root == nullptr) {
            // 新插入一个节点。新插入的节点一定是叶子节点，所以该节点的高度为1（类内初始化）
            return new Node(data, nullptr, nullptr, parent);
        } else if (root->data > data) {
            root->left = insert_recursion(root->left, root, data);
            // 插入后判断root是否失衡。因为插入的是root->left，所以只需要考虑root左边过高的情况
            if (abs(get_balance(root)) == 2) { // root节点失衡
                if (root->left != nullptr && data < root->left->data) {
                    // 执行右单旋操作。
                    root = right_rotate(root);
                } else {
                    // 执行左右旋操作。
                    root = left_right_rotate(root);
                }
            }
        } else if (root->data < data) {
            root->right = insert_recursion(root->right, root, data);
            // 判断root是否失衡
            if (abs(get_balance(root)) == 2) {
                if (root->right != nullptr && data > root->right->data) {
                    // 执行左单旋。
                    root = left_rotate(root);
                } else {
                    // 执行右左旋。
                    root = right_left_rotate(root);
                }
            }
        } else {
            printf("ERROR! data already exist.\n");
        }
        // 无论插入情况如何，都要在插入后更新root节点的节点高度
        update_height(root);
        return root;
    }

    // 删除(递归实现)
    Node *delete_recursion(Node *root, int data) {
        if (root != nullptr) {
            if (root->data == data) { // 找到要删除的节点
                printf("delete: %d\n", data);
                if (root->right == nullptr && root->left != nullptr) { // root只有左孩子，没有右孩子
                    if (root->parent != nullptr) { // 考虑root是否是整个树的根节点
                        if (root->data > root->parent->data) { // root是root->parent的右孩子
                            root->parent->right = root->left;
                        } else { // root是root->parent的左孩子
                            root->parent->left = root->left;
                        }
                        update_height(root->parent); // 因为删除了root节点，所以要更新root->parent节点的高度
                    }
                    root->left->parent = root->parent; // 更新父节点指针
                    // 执行平衡操作? 似乎多余? root->left本来就是平衡的，只是取代了root，对root->left的平衡性没有影响。
                    // root->left = balance(root->left);
                    Node *temp = root->left;
                    delete root;
                    root = temp; // root节点从树中删除，root->left取代root
                } else if (root->left == nullptr && root->right != nullptr) { // root只有右孩子，没有左孩子
                    if (root->parent != nullptr) {
                        if (root->data > root->parent->data) {
                            root->parent->right = root->right;
                        } else {
                            root->parent->left = root->right;
                        }
                        update_height(root->parent);
                    }
                    root->right->parent = root->parent;
                    // root->right = balance(root->right);
                    Node *temp = root->right;
                    delete root;
                    root = temp;
                } else if (root->left != nullptr && root->right != nullptr) { // 左右孩子都有
                    Node *temp = root->right;
                    while (temp->left != nullptr) { // 找到root的右子树中的最小节点
                        temp = temp->left;
                    }
                    int val = temp->data;
                    root->right = delete_recursion(root->right, val);
                    root->data = val;
                    update_height(root); // root的右子树发生了变动，更新root的高度
                    root = balance(root);
                } else { // root是叶子节点
                    if (root->parent != nullptr) { // root存在父节点
                        if (root->parent->data < root->data) { // root是其父亲节点的右孩子
                            root->parent->right = nullptr; // 删去root节点
                        } else { // root是其父亲节点的左孩子
                            root->parent->left = nullptr;
                        }
                        update_height(root->parent);
                    }
                    delete root;
                    root = nullptr;
                }

            } else if (data < root->data) {
                root->left = delete_recursion(root->left, data);
                update_height(root);
                root = balance(root);
            } else {
                root->right = delete_recursion(root->right, data);
                update_height(root);
                root = balance(root);
            }
        } else {
            printf("Key to be deleted could not be found.\n");
        }

        return root;
    }

    // 查询(递归实现)
    bool search(const Node *root, const int &data) {
        if (root == nullptr) {
            return false;
        }
        if (root->data == data) {
            return true;
        } else if (data < root->data) {
            return search(root->left, data);
        } else {
            return search(root->right, data);
        }
    }

    // 获取节点高度
    int node_height(Node *node) {
        if (node == nullptr) {
            return 0;
        }
        return node->height;
    }

    // 更新节点高度
    void update_height(Node *root) {
        if (root != nullptr) {
            // update height
            root->height = std::max(node_height(root->left), node_height(root->right)) + 1;
        }
    }

    /**
     * @brief 获取node节点的平衡因子。
     * @param node 要获取平衡因子的节点
     * @return  - 如果node是非叶子节点，平衡因子 = 左子树高度 - 右子树高度;
     *
     *          - 如果node是叶子节点，平衡因子 = 1
     *
     *          - 如果node是空节点，平衡因子 = 0
     */
    int get_balance(Node *node) {
        if (node == nullptr) {
            return 0;
        }
        return node_height(node->left) - node_height(node->right);
    }

    /**
     * @brief root节点失衡，对root和root->left执行右旋操作。
     * @param root 失衡节点
     */
    Node *right_rotate(Node *root) {
        Node *childL = root->left;
        Node *childLR = childL->right;

        /**
         * 如果只使用了height属性，没有使用parent属性，则只需要 下面两行语句 和 root=Lchild 以及 四个update_height()即可完成旋转。
         * 如果使用了parent则需要加入剩余的代码。
         */
        root->left = childLR;
        childL->right = root;

        if (childLR != nullptr) {
            // 说明原root->left->right非空，需要更新它的父节点指针。
            childLR->parent = root;
        }
        childL->parent = root->parent;
        root->parent = childL;
        if (childL->parent != nullptr) {
            if (root->data < childL->parent->data) {
                // 原root节点挂载在root->parent的左边，旋转后将新树也挂载在左边
                childL->parent->left = childL;
            } else {
                // 否则挂载到右边
                childL->parent->right = childL;
            }
        }

        root = childL;
        update_height(root->left);
        update_height(root->right);
        update_height(root);
        update_height(root->parent); // 注意此处需要更新root->parent的高度，因为root->parent的其中一个子树(也就是root)高度改变，所以会影响root->parent的高度

        return root;
    }

    /**
     * @brief root节点失衡，对root和root->right进行左旋操作。
     * @param root 失衡节点
     */
    Node *left_rotate(Node *root) {
        Node *childR = root->right;
        Node *childRL = childR->left;

        root->right = childRL;
        childR->left = root;

        if (childRL != nullptr) {
            childRL->parent = root;
        }
        childR->parent = root->parent;
        root->parent = childR;
        if (childR->parent != nullptr) {
            if (childR->data < childR->parent->data) {
                childR->parent->left = childR;
            } else {
                childR->parent->right = childR;
            }
        }

        root = childR;
        update_height(root->left);
        update_height(root->right);
        update_height(root);
        update_height(root->parent);

        return root;
    }

    /**
     * @brief 左右旋
     */
    Node *left_right_rotate(Node *root) {
        // 先对root->left和root->left->right进行左单旋
        root->left = left_rotate(root->left);
        // 在对root和root->left进行右单旋
        return right_rotate(root);
    }

    /**
     * @brief 右左旋
     */
    Node *right_left_rotate(Node *root) {
        // 先对root->right和root->right->left进行右单旋
        root->right = right_rotate(root->right);
        // 再对root和root->right进行左单旋
        return left_rotate(root);
    }

    // 平衡root节点
    Node *balance(Node *root) {
        int balance_factor = get_balance(root);
        if (abs(balance_factor) == 2) {
            if (balance_factor < 0) { // root节点的右子树高度 > 左子树高度
                if (get_balance(root->right) == 1) { // root->right的左子树高度 > 右子树高度，root节点符合RL失衡，执行左右双旋
                    root = right_left_rotate(root);
                } else { // root->right的右子树高度 > 左子树高度，root节点符合RR失衡，执行左单旋
                    root = left_rotate(root);
                }
            } else { // root节点的右子树高度 < 左子树高度
                if (get_balance(root->left) == 1) { // root->left的左子树高度 > 右子树高度，root节点符合LL失衡，执行右单旋
                    root = right_rotate(root);
                } else { // root->right的右子树高度 > 左子树高度，root节点符合LR失衡，执行右左双旋
                    root = left_right_rotate(root);
                }
            }
        }
        return root;
    }

    void delete_tree(AVLTree::Node *root) {
        if (root == nullptr) {
            return;
        }
        delete_tree(root->left);
        delete_tree(root->right);
        printf("released node: %d\n", root->data);
        delete root;
    }
};

void printInOrder(AVLTree::Node *root) {
    if (root == nullptr) {
        return;
    }
    printInOrder(root->left);
    printf("%d ", root->data);
    printInOrder(root->right);
}

int main() {
    AVLTree avl;

    int *arr = new int[12]{10, 20, 45, 30, 12, 40, 50, 25, 14, 52, 75, 19};

    for (int i = 0; i < 12; ++i) {
        avl.insert_node(arr[i]);
    }

    for (int i = 0; i < 12; ++i) {
        if (avl.search(arr[i])) {
            printf("find: %d\n", arr[i]);
            avl.delete_node(arr[i]);
        }
    }

    delete[] arr;

    return 0;
}
```

