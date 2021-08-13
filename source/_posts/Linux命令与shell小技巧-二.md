---
title: Linux命令与shell小技巧(二)
date: 2021-08-13 22:05:57
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

### 常用命令

#### cat 命令

`cat file1 file2 file3 ...`将多个文件内容进行拼接并显示到 stdout。

可以通过管道操作符(|)将数据作为 cat 命令的输入，然后和另外的文件拼接显示：

`echo "Text through stdin" | cat - file`将从标准输入获取的数据和文件 file 的内容拼接起来显示，其中-被作为标准输入的文件名。

`cat -s file`可以去掉文件中的连续空行再进行显示：

```sh
echo -e "test\n\ntest\n\ntest" | cat
# test
#
#
# test
#
#
#test
echo -e "test\n\ntest\n\ntest" | cat -s
# test
#
# test
#
# test
```

`test -T file`可以将制表符(\t)显示为^I，有助于发现缩进错误：

```sh
echo -e "test\ttest" | cat
# test  test
echo -e "test\ttest" | cat -T
# test^Itest
```

`cat -n file`可以为每一行加上行号显示，默认会为空行也加上行号

`cat -nb file`只为非空行添加上号显示

```sh
echo -e "test\n\ntest\n\ntest" | cat -n
# 1 test
# 2
# 3 test
# 4
# 5 test
echo -e "test\n\ntest\n\ntest" | cat -nb
# 1 test
#
# 2 test
#
# 3 test
```

#### find 命令

`find base_path`列出给定目录下的所有文件和子目录

find 命令默认将结果进行打印，可以使用`-print`选项来显示指定，默认情况下(-print)会使用换行符(\n)来分隔每个文件名和目录，也可以通过使用`-print0`参数使用空字符(\0)作为分隔符，其主要用途是可以将包含换行符和空格符的文件名传递给`xargs`命令使用。

`find base_path -name filename`可以通过匹配文件名进行查找，文件名可以使用通配符\*

`find base_path -iname filename`在查找时可以忽略大小写

<!-- more -->

```sh
# -maxdepth 限定查找深度
find ~ -maxdepth 1 -name '*RC'
#
find ~ maxdepth 1 -iname '*RC'
# /home/somebody/.bashrc
# /home/somebody/.zshrc
# /home/somebody/.vimrc
```

> 文件名使用通配符时因该放入单引号中，shell 会扩展没有使用引号或者使用双引号的通配符

`find base_path -name filenameA -a -name filenameB`通过逻辑与进行查找

`find base_path -name filenameA -o -name filenameB`通过逻辑或进行查找

```sh
find ~ -maxdepth 1 -name '*rc' -a -name '*zsh*'
# /home/somebody/.zshrc
find ~ -maxdepth 1 -name '*zsh*' -o -name '*bash*'
# /home/somebody/.zshrc
# /home/somebody/.bashrc
# /home/somebody/.zsh_history
# /home/somebody/.bash_history
```

`find base_path -path sub_path`可以限制查找的路径：

```sh
find ~ -maxdepth 2 -name test
# /home/somebody/Documents/test
# /home/somebody/.nvm/test
find ~ -maxdepth 2 -path '*/Documents/*' -name test
# /home/somebody/Documents/test
```

`find base_path -regex pattern`可以使用正则表达式进行精确查找

`find base_path ! expression`可以进行否定查找

```sh
find ~ -maxdepth 2 -name test
# /home/somebody/Documents/test
# /home/somebody/.nvm/test
find ~ -maxdepth 2 ! -path '*/Documents/*' -name test
# /home/somebody/.nvm/test
```

`find base_path -maxdepth number`指定最大的查找深度

`find base_path -mindepth number`指定开始查找的最小深度

```sh
find ~ -maxdepth 4 -name test
# /home/somebody/Documents/test
# /home/somebody/.nvm/test
# /home/somebody/vscode-server/extensions/yzhang.markdown-all-in-one-3.4.0/test
find ~ -maxdepth 4 -mindepth 3 -name test
# /home/somebody/vscode-server/extensions/yzhang.markdown-all-in-one-3.4.0/test
```

`find base_path -type filetype`指定查找文件类型

- -type f 普通文件
- -type l 符号链接
- -type d 目录
- -type c 字符设备
- -type b 块设备
- -type s 套接字
- -type p FIFO

`find base_path -atime number`按访问时间查找

`find base_path -mtime number`按修改时间查找

`find base_path -ctime number`按变化时间查找

以上时间均以天为单位，可以加上+、-号，表示大于或小于指定天数

`-amin`、`-mmin`、`-cmin`则使用分钟进行搜索

`find base_path -newer file`以指定文件做参考，查找比指定文件更新(更近的修改时间)的文件

`find base_path -size size_number`可以按文件大小查找，同样支持使用+、-号指定大于或小于某个大小

- -size b 块(512 字节)
- -size c 字节
- -size w 字(2 字节)
- -size k 千字节(kb)
- -size M 兆字节(Mb)
- -size G 吉字节(GB)

`find base_path -perm`可以按文件权限查找

`find base_path -user`可以按文件所有权查找

`find base_path -type f -name filename --delete`可以删除匹配的文件

`find base_path -type f -name filename -exec command`可以对匹配文件执行指定操作

`-exec`和`printf`搭配使用可以生成输出信息：

```sh
find ~ -maxdepth 1 -name '*rc' -exec printf 'RC File: %s\n' {} \;
# RC File: /home/somebody/.bashrc
# RC File: /home/somebody/.zshrc
# RC File: /home/somebody/.vimrc
```

> 上面命令结尾的分号不能省略，否则`-exec`无法识别要执行什么命令

`-prune`命令可以实现特定目录或文件的排除，在搜索时排除某些文件或目录的技巧叫做**修剪**，下面例子中，将.git 目录排除，然后打印出所有文件：

```sh
find . -name '.git' -prune -o -type f -print
```
