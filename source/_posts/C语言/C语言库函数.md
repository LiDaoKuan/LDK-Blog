---
title: C库函数
date: 2025-07-06
description: C语言实用库函数
categories: C语言
---

- `<stdio.h>`
    - `void perror(const char* err)`
    - `int sprintf(char *str, const char *format, ...)`
- `<stdlib.h>`
    - `int system(const char* command)`
        在windows系统中，system函数直接在控制台调用一个command命令。  在Linux/Unix系统中，system函数会调用fork函数产生子进程，由子进程来执行shell command命令，命令执行完后随即返回原调用的进程。
    - `unsigned long int strtoul(const char *str, char **endptr, int base);`函数
- `<string.h>`
    - `char *strndup(const char *s, size_t n)`函数
    - `int strncmp(const char *str1, const char *str2, size_t n)`函数
    - `int strcmp(const char *str1, const char *str2)`函数
    - `int strncasecmp(const char *s1, const char *s2, size_t n)`函数
    - `char *strchr(const char *str, int c);`函数
- `<ctype.h>`
    - `int toupper(int c);`：将小写字母转换为大写字母
    - `int isalnum(int c);`：判断字符是不是字母或者数字
- 

