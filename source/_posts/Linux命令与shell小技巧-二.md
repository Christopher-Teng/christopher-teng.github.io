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

#### xargs 命令

xargs 命令可以从标准输入读取一系列参数，然后使用这些参数来执行指定命令，因此一般情况下 xargs 都紧跟在管道操作符后面。

xargs 默认使用 echo 命令将从 stdin 读取的数据重新输出，并且会把多行数据转换成单行：

```sh
cat test
# 1 2 3
# 4 5 6
# 7 8 9
cat test | xargs
# 1 2 3 4 5 6 7 8 9
```

`xargs -n number`可以限制每次调用命令时用到的参数，可以通过这一特性将单行输入转换成多行：

```sh
cat test1
# 1 2 3 4 5 6 7 8 9
cat test1 | xargs -n 3
# 1 2 3
# 4 5 6
# 7 8 9
```

`xargs -d delimiter`可以指定分隔符。xargs 默认使用空白字符作为分隔符，当遇到文件或是目录名中有空格甚至是换行时，使用默认分隔符来分割输入就会出错：

```sh
cat test2
# 1 2 3,4 5 6,7 8 9
cat test2 | xargs -n 1
# 1
# 2
# 3,4
# 5
# 6,7
# 8
# 9
cat test2 | xargs -d , -n 1
# 1 2 3
# 4 5 6
# 7 8 9
```

xargs 命令常常和 find 命令结合使用，执行一些 find 命令的-exec 参数无法做到的复杂操作，但是如果 find 命令的查找结果中包含空白字符时，直接使用管道操作符传递给 xargs 命令会因为默认分隔符的原因出错，这是可以使用 find 命令的`-print0`参数将查找结果通过 NULL 字符(0)来分隔，然后通过 xargs 命令的`-0`参数来接受，就可以正确处理包含空格的情况：

```sh
cat "test 1" "test 2" "test 3"
# test 1
# test 2
# test 3
ls
# 'test 1' 'test 2' 'test 3'
find . -name "test *" | xargs cat
# cat: ./test: No such file or directory
# cat: 2: No such file or directory
# cat: ./test: No such file or directory
# cat: 1: No such file or directory
# cat: ./test: No such file or directory
# cat: 3: No such file or directory
find . -name "test *" | xargs -n 1
# ./test
# 1
# ./test
# 2
# ./test
# 3
find . -name "test *" -print0 | xargs -0 cat
# test 1
# test 2
# test 3
```

`xargs -I {} cmd {}`，使用参数`-I`可以指定替换字符串，这个字符串会在 xargs 命令解析输入时被参数替换掉：

```sh
ls -F
# 'test 1' 'test 2' 'test 3' test/
ls ./test
#
find . -name "test *" -print0 | xargs -0 mv ./test
# mv: target './test 3' is not a directory
find . -name "test *" -print0 | xargs -0 -I {} mv {} ./test
ls -F
# test/
ls ./test
# 'test 1' 'test 2' 'test 3'
```

#### tr 命令

tr 是 translate 的缩写，该命令可以对来自标准输入的内容进行字符替换、字符删除和重复字符压缩。

tr 命令只能通过 stdin(标准输入)接受输入(无法通过命令行参数接受)，其调用格式为：`tr [ options ] set1 set2`，来自标准输入的字符会按照位置从 set1 映射到 set2(set1 中的第一个字符映射到 set2 中的第一个字符，set1 中的第二个字符映射到 set2 中的第二个字符，以此类推)，然后将输出写入 stdout(标准输出)。set1 和 set2 是字符类或字符组，如果两者长度不相等，那么 set2 会不断复制 set1 的最后一个字符，直到长度与 set1 相等；如果 set2 的长度大于 set1，则 set2 中长度大于 set1 的那一部分字符会被完全忽略。

`tr 'a-zA-Z' 'n-za-mN-ZA-M'`，这是一个著名加密算法 ROT13 的实现，该替换模式会把字符顺序移动 13 位，文本的加密和解密都是用同一个函数实现：

```sh
echo 'some messages here' | tr 'a-zA-Z' 'n-za-mN-ZA-M' > test
cat test
# fbzr zrffntrf urer
cat test | tr 'a-zA-Z' 'n-za-mN-ZA-M'
# some messages here
```

> tr 命令的参数中，需要定义集合时，只需要使用**“起始字符-终止字符”**的方式，如果起始字符到终止字符不是有效的连续字符序列，则该写法被视为包含 3 个元素的集合(**“起始字符、-、终止字符”**)。

`tr -d set`可以从 stdin 中删除指定集合的字符：

```sh
cat test
# som0e me3ssa8ges h60er8e
cat test | tr -d '0-9'
# some messages here
```

`tr -c set1 set2`可以将不在集合 set1 中字符替换成 set2 中的字符，`tr -d -c set1`可以删除所有不在 set1 中的字符：

```sh
cat test
# som0e me3ssa8ges h60er8e
cat test | tr -c 'a-zA-Z \n' '\0'
# some messages here
cat test | tr -d -c 'a-zA-Z \n'
# some messages here
```
