---
title: Linux命令与shell小技巧(三)
date: 2021-08-22 10:02:29
tags:
  - Linux
  - Shell
categories:
  - 其他
---

本文搜集记录了一些 Linux 下的命令和 shell 脚本使用技巧，内容主要来自：

{% blockquote [USA] Clif Flynt [IND] Sarath Lakshman [IND] Shantanu Tushar,Linux Shell Scripting Cookbook %}
Linux Shell 脚本攻略（第 3 版）—— 门佳 译
{% endblockquote %}

## 文本操作

### grep 命令

`echo -e "this is a word\nnext line" | grep word`使用 grep 从标准输入中搜索匹配特定模式的文本行

`grep pattern file`或`grep "pattern" file`从文件中搜索匹配特定模式的文本行

`grep "pattern" file1 file2 file3`同时从多个文件中搜索

`grep --color=auto "pattern" file`在输出中着重标记出匹配到的模式，参数--color 对在命令中的放置位置没有强制要求，但是通常作为第一个选项出现

`grep -E "[a-z]+" file`或者`egrep "[a-z]+" file`使用扩展的正则表达式进行搜索，而 grep 默认使用基础正则表达式

`grep -o "pattern" file`只输出匹配到的文本

`grep -v "pattern" file`输出不匹配的所有行

`grep -c "pattern" file`统计成功匹配的文本行数，加上参数`-v`可以反转匹配结果，统计不匹配的文本行数

> 使用`-c`参数只是统计出成功匹配的文本行数，而不是匹配的次数，如果要统计匹配的次数，可以使用如下的技巧：
>
> `grep -o "pattern" | wc -l`

```sh
cat test
# 1wds
# 2sdsad
# 3sds4sd
# 5dsd6da
egrep -c "[0-9]+" test
# 4
egerp -o "[0-9+]" test
# 1
# 2
# 3
# 4
# 5
# 6
egrep -o "[0-9]+" test | wc -l
# 6
```

<!-- more -->

`grep -n "pattern" file`可以显示出匹配行的行号，`grep -n "pattern" file1 file2`如果有多个文件时，会加上文件名和行号

`grep -b "pattern" file`输出匹配行的偏移量，`grep -bo "pattern" file`则会输出匹配结果的偏移量，偏移量是从 0 开始计算的

```sh
cat test
# 1wds
# 2sdsad
# 3sds4sd
# 5dsd6da
egrep -b "[0-9]+" test
# 0:1wds
# 5:2sdsad
# 12:3sds4sd
# 20:5dsd6da
egrep -bo "[0-9]+" test
# 0:1
# 5:2
# 12:3
# 16:4
# 20:5
# 24:6
```

`grep -l "pattern" file1 file2`列出匹配成功的文件列表，`grep -L "pattern" file1 file2`则列出没有匹配的文件列表

```sh
cat test1
# 1wds
# 2sdsad
# 3sds4sd
# 5dsd6da
cat test2
# 123
# 4
# 56
egrep -l "[a-z]+" test1 test2
# test1
egrep -L "[a-z]+" test1 test2
# test2
```

`grep "pattern" path -R`会在指定路径中递归的搜索

`grep -i "pattern" file`搜索时忽略大小写

`grep -e "pattern1" -e "pattern2" file`可以同时指定多个匹配模式

`grep -f pattern_file file`可以从文件中读取匹配模式(一个匹配模式一行)，然后进行搜索

`grep "pattern" path -R --include "pattern"`可以在搜索过程中用通配符指定某些文件，相反的，参数`--exclude`在搜索过程中使用通配符排除某些文件，`--exclude-dir`可以排除目录

`grep -Z "pattern" file`可以使用 0 值字符(\0)作为文件名的终结符，结合参数`-l`或`-L`可以搜索出特定文件，然后传递给 xargs 执行下一步操作：

```sh
grep "pattern" -lZ . -R | xargs -0 rm
```

`grep -q "pattern" file`使用静默模式搜索，不会输出搜索结果，只会在执行搜索后返回退出码，执行成功返回退出码 0，否则返回非 0 退出码

`grep -A n "pattern" file`可以输出匹配行以及之后的 n 行，`grep -B n "pattern" file`可以输出匹配行和之前的 n 行

`grep -A n -B m "pattern" file`可以输出匹行以及之前的 m 行和之后的 n 行

`grep -C n "pattern" file`可以输出匹配行和前后 n 行

```sh
cat test
# xxx
# 123
# abc
# 123
# xxx
grep -A 2 "abc" test
# abc
# 123
# xxx
grep -B 2 "abc" test
# xxx
# 123
# abc
grep -C 2 "abc" test
# xxx
# 123
# abc
# 123
# xxx
grep -A 2 -B 1 "abc" test
# 123
# abc
# 123
# xxx
```
