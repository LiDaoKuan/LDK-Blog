---
title: C++ string分割
date: 2025-07-06
categories: 实用代码段
tags: [C++, string, 实用代码]
---

### string分割

#### 方法一：使用`find()`和`substr()`.

##### 用字符分割字符串：

```cpp
// 使用字符分割
void Stringsplit(const string& str, const char split, vector<string>& res)
{
	if (str == ""){
        return
    };
	//在字符串末尾也加入分隔符，方便截取最后一段
	string strs = str + split;
	size_t pos = strs.find(split);

	// 若找不到内容则字符串搜索函数返回 npos
	while (pos != strs.npos)
	{
		string temp = strs.substr(0, pos);
		res.push_back(temp);
		//去掉已分割的字符串,在剩下的字符串中进行分割
		strs = strs.substr(pos + 1, strs.size());
		pos = strs.find(split);
	}
}
```

##### 用字符串分割字符串

> 整个字符串`splits`作为分隔符。

```cpp
// 使用字符串分割
void Stringsplit(const string& str, const string& splits, vector<string>& res)
{
	if (str == "")		return;
	//在字符串末尾也加入分隔符，方便截取最后一段
	string strs = str + splits;
	size_t pos = strs.find(splits);
	int step = splits.size();

	// 若找不到内容则字符串搜索函数返回 npos
	while (pos != strs.npos)
	{
		string temp = strs.substr(0, pos);
		res.push_back(temp);
		//去掉已分割的字符串,在剩下的字符串中进行分割
		strs = strs.substr(pos + step, strs.size());
		pos = strs.find(splits);
	}
}
```

#### 方法二：使用`istringstream`.

