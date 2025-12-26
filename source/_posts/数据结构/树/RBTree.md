---
title: 红黑树
date: 2025-07-14
updated: 2025-07-15
tags: [数据结构, 红黑树, 二叉树, Cpp]
categories: 数据结构
---

### 概念

> 一种自平衡的二叉搜索树。每个节点额外存储了一个 color 字段 ("RED" or "BLACK")，用于确保树在插入和删除时保持平衡。
>
> 红黑树是 4 阶 B 树（[2-3-4 树](https://oi-wiki.org/ds/2-3-4-tree/)）的变体。

### 特点

红黑树本身也是二叉搜索树，具有所有二叉搜索树的特点。

**一棵合法的红黑树必须遵循以下性质**：

1. <a name="性质1">（节点颜色）所有节点为红色或黑色</a>。
2. <a name="性质2">（根节点）**根节点必须是黑色**</a>。
3. <a name="性质3">（叶子节点）`NIL` 节点（空叶子节点）都是黑色</a>。
4. <a name="性质4">（红色节点）红色节点的左右子节点都为黑色（从每个`NIL`节点到**根节点**的路径上不能有连续的两个红色节点）</a>。
5. <a name="性质5">（黑色节点）从<mark>任意节点</mark>到其所在子树的 `NIL` 节点的每条路径上的黑色节点数量相同（简称黑高）</a>。

下图为一个合法的红黑树：

![红黑树](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250623201450979.png)

### 扩展特点

- 最长路径**不超过**最短路径的两倍。
- 由上一特点可得：任一节点的左右子树的高度差不会超过**2倍**。

> 对比平衡二叉树：平衡二叉树要求左右子树高度相差不超过1，而红黑树要求左右子树高度差不超过2倍。由此看来平衡二叉树对平衡的要求更严格，插入时进行的旋转操作更多。

### 实现

#### 插入

插入的新节点默认是<mark>红色</mark>节点。因为如果对一个红黑树插入一个黑色节点，无论黑色节点插在哪里，都会违反红黑树基本特点中的[第`5`条](#性质5)（因为插入之前的红黑树肯定满足以上所有特点，但插入后一定会破坏第`5`条）。

那么在插入红色节点的情况下，可能会违反基本特点中的[第`4`条特点](#性质4)（不能有两个连续的红色节点）。如果没有违反特点，则不需要调整。如果违反了特点，就需要进行旋转，分为三种情况：

- 新插入的节点是根节点：直接将根节点变黑（只有在**插入之前树为空**的情况下才会发生）。

- 新插入节点的**叔叔节点**（父节点的兄弟节点）是**红色**：
  - 调整新插入的节点的**父亲、叔叔、爷爷**三个节点的颜色：红色变为黑色，黑色变为红色。
  - 令爷爷节点当作新插入节点，重新判断（循环或者递归）。
  
- 新插入节点的**叔叔节点**是**黑色**：

  - 判断`LL, LR, RR, RL`四种失衡类型，然后旋转。因为只有连续两个红色节点才需要旋转，所以可以确定新插入节点的父节点一定是红色的。据此判断失衡类型。

    - `LL`：

      ![LL情况-右旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/image%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250727161732_25.jpg)

    - `LR`：

      ![LR情况-左右双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/image%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250727161726_23.jpg)

    - `RR`：
    
      ![RR情况-左旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/image%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250727161735_26.jpg)
    
    - `RL`：
    
      ![RL情况-右左双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/image%E5%BE%AE%E4%BF%A1%E5%9B%BE%E7%89%87_20250727161716_22.jpg)


#### 删除

删除操作是红黑树逻辑最复杂的操作，主要是删除黑色节点时，会导致被删除节点所在路径上的黑色节点数量减`1`，导致违反上述基本性质中的[第`5`条性质](#性质5)。而删除红色节点则相对简单。

##### 删除的情况分类

对被删除节点的情况进行分类。

- ###### 被删除节点只有左孩子/只有右孩子

  **此时被删除节点一定为黑色节点**，因为如果是红色节点，那么一定是左右子树都存在或者左右子树都不存在，否则就会违背上述[第`5`条性质](#性质5)。

  确定了被删除节点一定为**黑色**后，可以推得：被删除节点的**仅有的孩子节点**一定是红色。因为被删除节点的其中一个子树是空的，那么剩下的那个非空的子树中一定不会存在黑色节点，否则就会违反基本性质中的[第5条性质](#性质5)。

  具体情况和对应操作见下图：

  ![image-20250728155640665](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250728155640665.png)

  可见，只需要将唯一的那个子节点向上提升，替代要删除的节点即可。

- ###### 被删除节点左右孩子都有

  可以转换为其他两种情况：用要删除的节点的右子树上的最小节点替换要删除的节点，然后删除右子树上的最小节点。如此递归，可转化为另外两种情况。

- ###### 被删除节点没有孩子

  - **被删除节点为黑色**：
  
    因为删除了黑色节点后，从该节点到根节点的路径上少了一个黑色节点，破坏了[第`5`条性质](#性质5)，所以需要观察兄弟节点和父亲节点颜色，分情况处理这缺失的一个黑色节点：
  
    - 兄弟节点为黑色：
  
      - 并且兄弟节点有一个与它<mark>方向一致</mark>的红色节点。父亲节点颜色随意:
  
        <mark>方向一致</mark>：指的是`brother`是`father`的左子节点并且`son`是`brother`的左子节点，或者`brother`是`father`的右子节点并且`son`是`brother`的右子节点。即：`father`、`brother`、`son`<三点共线>。
  
        > 此时执行**左旋**(`RR`情况下)或者**右旋**(`LL`情况下)。并且在旋转之前，先按步骤进行变色：son变为**黑色**，brother变为father的颜色，father变为黑色。
  
        ![兄黑同红子-红子变黑-兄变父色-父变黑色-外加单旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250729193857476.png)
  
      - 并且兄弟节点有一个与它<mark>方向相反</mark>的红色节点，**同时兄弟节点没有与它<mark>方向一致</mark>的红色子节点**。父亲节点颜色随意：
  
        <mark>方向相反</mark>：参考方向一致。`father`、`brother`、`son`三点不共线，即认为是方向相反。
  
        > 先让兄弟节点son变为父亲节点father的颜色，再让父亲节点father颜色变黑。最后分析情况执行**左右双旋**或者**右左双旋**。
  
        ![兄黑反红子-兄变父色-父变黑色-外加双旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250729193004686.png)
  
      - 并且**兄弟节点没有红色子节点**。**父亲**节点为<font style="background: white" color="RED">红色</font>：
  
        > 兄弟节点变红，父亲节点变黑。
  
        ![兄黑父红无红子-兄变红-父变黑](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250729230437194.png)
  
      - 并且**兄弟节点没有红色子节点**。**父亲**节点为<font style="background: white" color="BLACK">黑色</font>：
  
        > 兄弟节点变为红色，双黑标记上移至父亲节点（将父亲节点当作被删除节点）。递归判断父亲节点的情况。
  
        ![兄黑父黑-兄变红-父变双黑-递归判断](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250730001039457.png)
  
    - **兄弟**节点为<font style="background: white" color="RED">红色</font>：
  
      此时**兄弟节点没有红色子节点**，也不可能有红色子节点（[性质4](#性质4)）。同时**父亲**节点必定为<font style="background: white" color="black">黑色</font>（[性质4](#性质4)）。执行操作：
  
      > 兄弟节点变黑色，父亲节点变红色。然后左旋或者右旋父亲节点。（将父亲节点下移，兄弟节点上移）
      
      ![兄红父黑-先变色，再左旋或右旋](https://image-1258881983.cos.ap-beijing.myqcloud.com/imageimage-20250729192538724.png)
    
  - **被删除节点为红色**：
  
    最简单的情况。直接删除该节点。（因为没有左右孩子，并且不影响红黑树基本性质，所以可以直接删除，不做任何额外操作）

#### 查询

查询思路与二叉搜索树相同。

#### Linux内核风格的红黑树实现

本来应该写C++实现的红黑树的，毕竟用`class`封装起来更易用。不巧前几天看到了`linux kernel`风格的红黑树实现，感觉侵入式设计本身也有其优点。所以就抄下来了。

``` c:rbtree.h
/*
  Red Black Trees
  (C) 1999  Andrea Arcangeli <andrea@suse.de>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

  linux/include/linux/rbtree.h

  To use rbtrees you'll have to implement your own insert and search cores.
  This will avoid us to use callbacks and to drop drammatically performances.
  I know it's not the cleaner way,  but in C (not in C++) to get
  performances and genericity...

  Some example of insert and search follows here. The search is a plain
  normal search over an ordered tree. The insert instead must be implemented
  int two steps: as first thing the code must insert the element in
  order as a red leaf in the tree, then the support library function
  rb_insert_color() must be called. Such function will do the
  not trivial work to rebalance the rbtree if necessary.

-----------------------------------------------------------------------
static inline struct page * rb_search_page_cache(struct inode * inode,
						 unsigned long offset)
{
	rb_node_t * n = inode->i_rb_page_cache.rb_node;
	struct page * page;

	while (n)
	{
		page = rb_entry(n, struct page, rb_page_cache);

		if (offset < page->offset)
			n = n->rb_left;
		else if (offset > page->offset)
			n = n->rb_right;
		else
			return page;
	}
	return NULL;
}

static inline struct page * __rb_insert_page_cache(struct inode * inode,
						   unsigned long offset,
						   rb_node_t * node)
{
	rb_node_t ** p = &inode->i_rb_page_cache.rb_node;
	rb_node_t * parent = NULL;
	struct page * page;

	while (*p)
	{
		parent = *p;
		page = rb_entry(parent, struct page, rb_page_cache);

		if (offset < page->offset)
			p = &(*p)->rb_left;
		else if (offset > page->offset)
			p = &(*p)->rb_right;
		else
			return page;
	}

	rb_link_node(node, parent, p);

	return NULL;
}

static inline struct page * rb_insert_page_cache(struct inode * inode,
						 unsigned long offset,
						 rb_node_t * node)
{
	struct page * ret;
	if ((ret = __rb_insert_page_cache(inode, offset, node)))
		goto out;
	rb_insert_color(node, &inode->i_rb_page_cache);
 out:
	return ret;
}
-----------------------------------------------------------------------
*/

#ifndef RBTREE_H
#define RBTREE_H

#pragma pack(1)
struct rb_node {
    struct rb_node *rb_parent;
    struct rb_node *rb_right;
    struct rb_node *rb_left;
    char rb_color;
#define RB_RED     0
#define RB_BLACK    1
};
#pragma pack()

struct rb_root {
    struct rb_node *rb_node;
};

#define RB_ROOT (struct rb_root){ (struct rb_node*)0, }
#define rb_entry(ptr, type, member) \
    ( (type*) ((char*)(ptr) - (unsigned long)(&((type*)0)->member)) )

#ifdef __cplusplus
extern "C" {
#endif

extern void rb_insert_color(struct rb_node *node, struct rb_root *root);
extern void rb_erase(struct rb_node *node, struct rb_root *root);

extern struct rb_node *rb_next(struct rb_node *);
extern struct rb_node *rb_prev(struct rb_node *);
extern struct rb_node *rb_first(struct rb_root *);
extern struct rb_node *rb_last(struct rb_root *);

extern void rb_replace_node(const struct rb_node *victim, struct rb_node *newnode, struct rb_root *root);

#ifdef __cplusplus
}
#endif

/**
 * 在红黑数的parent节点下插入新节点node. 该函数不关心红黑数的平衡
 * @param node 指向要插入的新节点
 * @param parent 指向新节点在树中的父节点
 * @param link 一个指向指针的指针. 它指向父节点 parent 中应该挂载新节点的位置（即 parent->rb_left或 parent->rb_right的地址）
 */
static inline void rb_link_node(struct rb_node *node, struct rb_node *parent, struct rb_node **link) {
    node->rb_parent = parent; // 设置父亲节点
    node->rb_color = RB_RED; // 初始化颜色
    node->rb_left = node->rb_right = (struct rb_node *)0; // 叶子结点置null、
    // 将新节点node赋值给父亲节点中对应的子指针, 完成节点在树中的连接
    *link = node;
}

#endif // RBTREE_H
```

```c:rbtree.c
#include "rbtree.h"
#include <bits/posix2_lim.h>

/* 对node节点和node->right节点进行左旋 */
static void __rb_rotate_left(struct rb_node *node, struct rb_root *root) {
    struct rb_node *right = node->rb_right;
    // 注意if里面是 = 赋值，不是比较大小！
    if ((node->rb_right = right->rb_left)) {
        // 能进入if语句，说明旋转前 node->rb_right->rb_left != nullptr.
        // 更新 node->rb_right->rb_left的父亲指针
        right->rb_left->rb_parent = node;
    }
    right->rb_left = node; // 至此左旋已经完成，但是还需要更新父亲指针
    // 更新父亲指针, 注意是赋值而不是比大小！
    if ((right->rb_parent = node->rb_parent)) {
        // 能进入if语句，说明旋转前node节点的父节点不为空（即: 旋转前node存在父节点）
        // 判断node旋转前是其父亲的 左子节点 还是 右子结点
        if (node == node->rb_parent->rb_left) {
            node->rb_parent->rb_left = right; // node先前是左子节点。那么现在right替代node成为node->parent的左子节点
        } else {
            node->rb_parent->rb_right = right;
        }
    } else {
        // 没有进入上面的if语句。说明旋转前node是整个树的根节点。
        // 更新right为新的根节点
        root->rb_node = right;
    }
    node->rb_parent = right;
}

static void __rb_rotate_right(struct rb_node *node, struct rb_root *root) {
    struct rb_node *left = node->rb_left;
    if ((node->rb_left = left->rb_right)) {
        left->rb_right->rb_parent = node;
    }
    left->rb_right = node;
    if ((left->rb_parent = node->rb_parent)) {
        if (node->rb_parent->rb_left == node) {
            node->rb_parent->rb_left = left;
        } else {
            node->rb_parent->rb_right = left;
        }
    } else {
        root->rb_node = left;
    }
    node->rb_parent = left;
}

/* 平衡新插入红黑树的红色节点node */
void rb_insert_color(struct rb_node *node, struct rb_root *root) {
    struct rb_node *parent;

    /* 如果新插入的节点是根节点，或者新插入的节点的父亲是黑色节点。则不会进入循环 */
    while (((parent = node->rb_parent)) && (parent->rb_color == RB_RED)) {
        struct rb_node *gparent = parent->rb_parent;
        // 父亲结点是爷爷节点的左子节点
        if (parent == gparent->rb_left) {
            {
                struct rb_node *uncle = gparent->rb_right;
                // 叔叔节点存在并且是红色
                if (uncle && uncle->rb_color == RB_RED) {
                    /* 叔变黑，父变黑，爷变红 */
                    uncle->rb_color = RB_BLACK;
                    parent->rb_color = RB_BLACK;
                    gparent->rb_color = RB_RED;
                    node = gparent; // 递归处理爷爷节点
                    continue;
                }
            }
            // 叔叔为黑色或者叔叔不存在
            if (parent->rb_right == node) {
                // 当前节点是 父亲节点 的 右子节点。先对parent和node进行左旋。否则不旋转
                __rb_rotate_left(parent, root);
                // 因为已经旋转完成，此时交换parent和node两个指针，方便后面对旋转后的parent进行操作
                struct rb_node *tmp = parent;
                parent = node;
                node = tmp;
            }
            // 如果之前执行了左旋: 此时再对 gparent 和 新parent(原node) 进行右旋
            // 如果之前没有执行左旋: 说明是三点共线情况. (node是parent的左子节点, parent是gparent的右子节点)
            parent->rb_color = RB_BLACK;
            gparent->rb_color = RB_RED;
            __rb_rotate_right(gparent, root);
        } else {
            // 父亲节点是爷爷节点的右子节点
            {
                struct rb_node *uncle = gparent->rb_left;
                // 叔叔存在并且是红色
                if (uncle && uncle->rb_color == RB_RED) {
                    /* 叔变黑，父变黑，爷变红 */
                    uncle->rb_color = RB_BLACK;
                    parent->rb_color = RB_BLACK;
                    gparent->rb_color = RB_RED;
                    node = gparent; // 递归处理爷爷节点
                    continue;
                }
            }

            /* 下面逻辑与上方最外层if语句类似 */
            if (parent->rb_left == node) {
                __rb_rotate_right(parent, root);
                struct rb_node *tmp = parent;
                parent = node;
                node = tmp;
            }

            parent->rb_color = RB_BLACK;
            gparent->rb_color = RB_RED;
            __rb_rotate_left(gparent, root);
        }
    }
    root->rb_node->rb_color = RB_BLACK;
}

/* 从root中删除 黑色 节点node. 其中node应当是叶子节点 */
static void __rb_erase_color(struct rb_node *node, struct rb_node *parent, struct rb_root *root) {
    struct rb_node *other;
    // 如果node==nullptr, 则 node!=root->rb_node一定成立（因为是删除函数，所以假设红黑数不为空）
    // 如果node!=nullptr, 判断node是否为黑色, 如果是黑色, 则判断是不是整个树的根节点(红色不可能是根节点), 是根节点则直接跳出循环
    while ((!node || node->rb_color == RB_BLACK) && node != root->rb_node) {
        if (parent->rb_left == node) {
            // other指向node的兄弟节点
            other = parent->rb_right;
            if (other->rb_color == RB_RED) {
                // 如果兄弟为红色，那么: 兄变黑，父变红，左旋父亲
                other->rb_color = RB_BLACK;
                parent->rb_color = RB_RED;
                __rb_rotate_left(parent, root);
                // 更新兄弟节点指针。并且这个新的兄弟节点必定是黑色。因为原红色兄弟节点的左孩子根据红黑树性质必须是黑色。
                // 这样就转化为了兄弟节点是黑色的情况
                other = parent->rb_right;
            }
            // 下面处理兄弟节点是黑色的情况
            // if: 兄弟左子树不存在或者兄弟的左子节点为黑色 && 兄弟的右子结点不存在或者兄弟的右子结点为黑色
            // 总结: 兄弟节点是黑色并且兄弟节点的两个子节点也是黑色(即便兄弟没有子节点，也会有两个隐藏的黑色空叶子节点)
            if ((!other->rb_left || other->rb_left->rb_color == RB_BLACK)
                && (!other->rb_right || other->rb_right->rb_color == RB_BLACK)) {
                // 兄弟变红。将"被删除的黑色"向上移动，转移到父亲节点上去解决
                other->rb_color = RB_RED;
                // 递归处理父亲结点.
                node = parent;
                parent = node->rb_parent;
            } else {
                // 兄弟节点的右子结点为黑色(即: 兄弟的左子节点为红色)
                if (!other->rb_right || other->rb_right->rb_color == RB_BLACK) {
                    // 通过变色和旋转将情况转换为: 兄弟节点的右子结点为红色的情况
                    struct rb_node *o_left;
                    if ((o_left = other->rb_left)) {
                        // 令兄弟节点的左子节点由红变黑
                        o_left->rb_color = RB_BLACK;
                    }
                    other->rb_color = RB_RED; // 兄弟节点变黑
                    __rb_rotate_right(other, root); // 右旋兄弟节点
                    other = parent->rb_right; // 更新新的兄弟节点
                }
                // 下面处理兄弟节点为黑色，其右子节点为红色的情况
                // 兄变父色，父变黑色，兄弟的右子结点变黑色。然后左旋父亲节点
                other->rb_color = parent->rb_color;
                parent->rb_color = RB_BLACK;
                if (other->rb_right) {
                    other->rb_right->rb_color = RB_BLACK;
                }
                __rb_rotate_left(parent, root);
                node = root->rb_node; // node指向根节点，退出循环
                break;
            }
        } else {
            // 上述情况的对称情况
            other = parent->rb_left;
            if (other->rb_color == RB_RED) {
                other->rb_color = RB_BLACK;
                parent->rb_color = RB_RED;
                __rb_rotate_right(parent, root);
                other = parent->rb_left;
            }
            if ((!other->rb_left ||
                 other->rb_left->rb_color == RB_BLACK)
                && (!other->rb_right ||
                    other->rb_right->rb_color == RB_BLACK)) {
                other->rb_color = RB_RED;
                node = parent;
                parent = node->rb_parent;
            } else {
                if (!other->rb_left ||
                    other->rb_left->rb_color == RB_BLACK) {
                    register struct rb_node *o_right;
                    if ((o_right = other->rb_right)) o_right->rb_color = RB_BLACK;
                    other->rb_color = RB_RED;
                    __rb_rotate_left(other, root);
                    other = parent->rb_left;
                }
                other->rb_color = parent->rb_color;
                parent->rb_color = RB_BLACK;
                if (other->rb_left) other->rb_left->rb_color = RB_BLACK;
                __rb_rotate_right(parent, root);
                node = root->rb_node;
                break;
            }
        }
    }
    // node最后一定会指向根节点。保证根节点是黑色
    if (node) {
        node->rb_color = RB_BLACK;
    }
}

// 从红黑树root中删除节点node
void rb_erase(struct rb_node *node, struct rb_root *root) {
    struct rb_node *child, *parent;
    int color;
    if (!node->rb_left) {
        child = node->rb_right; // 左子节点不存在, child指向右子结点
    } else if (!node->rb_right) {
        child = node->rb_left; // 右子节点不存在, child指向左子节点
    } else {
        // 左右子节点都存在
        struct rb_node *old = node; // 记录原node节点
        struct rb_node *left;
        node = node->rb_right;
        // 找到node的右子树上最小的节点
        while ((left = node->rb_left)) {
            node = left;
        }
        child = node->rb_right;
        parent = node->rb_parent;
        color = node->rb_color;

        if (child) {
            // 如果这个最小节点有没有右子结点，更新其父节点
            child->rb_parent = parent;
        }
        // workflow为了稳健性保留了这个判断。实际上if(parent)一定为true。即: else部分永远不会被执行
        if (parent) {
            if (parent->rb_left == node) {
                parent->rb_left = child; // 至此，最小节点从node的右子树中被完全删除。但还可以通过指针node访问
            } else {
                // parent->rb_left != node 说明，原node的右子树上只有一个节点
                parent->rb_right = child;
            }
        } else {
            root->rb_node = child;
        }
        if (node->rb_parent == old) {
            // 对应原node的右子树只有一个节点的情况
            parent = node; // 此句似乎无用，毕竟parent赋值完成后没用过，就又被赋值了
        }
        // 将原右子树的最小节点挂载到要删除的节点的位置上
        node->rb_parent = old->rb_parent;
        node->rb_color = old->rb_color;
        node->rb_right = old->rb_right;
        node->rb_left = old->rb_left;
        // 判断要删除的节点是不是整个树的根节点
        if (old->rb_parent) {
            // 判断要删除的节点是其父节点的 左子节点 还是 右子结点
            if (old->rb_parent->rb_left == old) {
                old->rb_parent->rb_left = node;
            } else {
                old->rb_parent->rb_right = node;
            }
        } else {
            root->rb_node = node;
        }
        // 记得更新左子节点的父节点指针
        old->rb_left->rb_parent = node;
        if (old->rb_right) {
            old->rb_right->rb_parent = node;
        }
        goto COLOR;
    }

    parent = node->rb_parent;
    color = node->rb_color;

    if (child) {
        child->rb_parent = parent;
    }
    if (parent) {
        if (parent->rb_left == node) {
            parent->rb_left = child;
        } else {
            parent->rb_right = child;
        }
    } else {
        root->rb_node = child;
    }

COLOR:
    // 此时的color是删除前右子树上的最小节点的color. 相当于将要删除节点与右子树上最小节点更换位置但是不更换颜色
    // 然后再将更换为之后的目标节点删除. 如果删掉的是黑色节点. 则必须进行调整
    if (color == RB_BLACK) {
        __rb_erase_color(child, parent, root);
    }
}

/* 获取红黑数root的最小节点 */
struct rb_node *rb_first(struct rb_root *root) {
    struct rb_node *n;

    n = root->rb_node;
    if (!n) return (struct rb_node *)0;
    while (n->rb_left) n = n->rb_left;
    return n;
}

/* 获取红黑数root的最大节点 */
struct rb_node *rb_last(struct rb_root *root) {
    struct rb_node *n;

    n = root->rb_node;
    if (!n) return (struct rb_node *)0;
    while (n->rb_right) n = n->rb_right;
    return n;
}

/* 获取红黑数中节点node的后继结点 */
struct rb_node *rb_next(struct rb_node *node) {
    /* 如果node有一个右子节点，则移动到该右子节点，然后尽可能地向左移动。 */
    if (node->rb_right) {
        node = node->rb_right;
        while (node->rb_left) node = node->rb_left;
        return node;
    }

    /* node没有右子节点。所有向左的节点都比我们小,
       因此任何 '后继' 节点必然在我们父节点的方向上
       向上遍历树：只要当前节点是其父节点的右子节点，就继续向上。
       当第一次遇到一个节点是其父节点的左子节点时，那个父节点就是我们的 '后继' 节点。 */
    while (node->rb_parent && node == node->rb_parent->rb_right) node = node->rb_parent;

    return node->rb_parent;
}

/* 获取红黑树中节点node的前序节点 */
struct rb_node *rb_prev(struct rb_node *node) {
    /* If we have a left-hand child, go down and then right as far
       as we can. */
    if (node->rb_left) {
        node = node->rb_left;
        while (node->rb_right) node = node->rb_right;
        return node;
    }

    /* No left-hand children. Go up till we find an ancestor which
       is a right-hand child of its parent */
    while (node->rb_parent && node == node->rb_parent->rb_left) node = node->rb_parent;

    return node->rb_parent;
}

/* 将红黑数root中的victim节点替换为newnode节点 */
void rb_replace_node(const struct rb_node *victim, struct rb_node *newnode, struct rb_root *root) {
    struct rb_node *parent = victim->rb_parent;
    if (parent) {
        // 更新parent的左/右子树指针指向newnode
        if (victim == parent->rb_left) {
            parent->rb_left = newnode;
        } else {
            parent->rb_right = newnode;
        }
    } else {
        root->rb_node = newnode;
    }
    // 更新原节点的左右子树的父亲节点指针指向newnode
    if (victim->rb_left) victim->rb_left->rb_parent = newnode;
    if (victim->rb_right) victim->rb_right->rb_parent = newnode;

    /* 复制原节点内的所有指针数据和颜色color到新节点中 */
    *newnode = *victim;
}
```

