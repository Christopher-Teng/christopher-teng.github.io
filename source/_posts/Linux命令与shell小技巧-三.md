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

### cut 命令

cut 命令按列，而不是按行切分文件，可用于处理使用固定宽度字段的文件、CSV 文件或是由空格分隔的文件(例如标准日志文件)

`cut -f FIELD_LIST filename`提取指定字段，FIELD_LIST 是需要显示的列，由列号组成，彼此之间用逗号分隔，例如 `cut -f 2,3 test` 将提取 test 文件中的第 2 列和第 3 列

`cut -f FIELD_LIST --complement filename`可以显示出没有被 FIELD_LIST 指定的字段

`cut -f FIELD_LIST -d delimiter filename`可以使用指定的分隔符提取字段

FIELD_LIST 除了使用列号和逗号的方式指定以外，还可以使用一种更简便的方式：

- N-
  从第 N 个开始到行尾
- N-M
  从第 N 个开始到第 M 个(包含第 M 个)
- -M
  从行首到第 M 个(包含第 M 个)

除了使用字段(空白符分隔)对列提取外，还可以指定其他的提取方式：

- -b 表示字节
- -c 表示字符

`--output-delimiter`可以指定输出分隔符，在显示多组数据时尤其有用

```sh
cat test
# xxx
# 123
# abc
# 123
# xxx
cat test | cut -c 1,3
# xx
# 13
# ac
# 13
# xx
cat test | cut -c 1,3 --output-delimiter " -- "
# x -- x
# 1 -- 3
# a -- c
# 1 -- 3
# x -- x
```

### sed 命令

sed 命令是 stream editor(流编辑器)的缩写，常常用于文本替换。

`cat file | sed 's/pattern/replace_string/'`使用简单的字符串或正则表达式进行匹配，并替换为新的字符串

`sed -i 's/pattern/replace_string/' file`可以用修改后的数据替换原文件，sed 默认操作是将替换后的结果输出而不替换原文件

`sed -i 's/pattern/replace_string/g' file`替换全部匹配的内容，sed 默认只替换首次匹配到的内容，如果是用类似 Ng 的形式，则指定替换第 N 次匹配的内容

`sed -i 's|pattern|replace_string|' file`使用|作为命令的分隔符，sed 将 s 后的符号视作分隔符，因此可以方便的改变默认分隔符/，如果模式或者替换内容中出现分隔符则因该对其使用\进行转义

`sed -i '/^$/d' file`使用/d 而不是 s/对匹配内容进行删除而不是替换，正则表达式^$匹配空行，因此该条命令会删除文件中的所有空行

`sed -i.bak 's/pattern/replace_string/' file`可以在替换文件的同时为原文件生成一个.bak 后缀的备份文件

参数`&`指代模式所匹配到的字符串：

```sh
cat test
# 123
# xxx
# 456
# abc
# 789
# xxx
sed 's/[a-z]\+/[&]/g' test
# 123
# [xxx]
# 456
# [abc]
# 789
# [xxx]
```

参数`\N`用来指代第 N 个子模式(出现在括号中的正则表达式)匹配的结果：

```sh
cat test
# 123
# xxx
# 456
# abc
# 789
# xxx
sed 's/\(^[0-9]\)\([0-9]\)\([0-9]$\)/\2\2\2/g' test
# 222
# xxx
# 555
# abc
# 888
# xxx
```

可以使用管道命令组合多个 sed 命令
`cat file | sed 's/pattern1/replace_string/g' | sed 's/pattern2/replace_string/g'`，
等同于使用分号分隔多个模式
`cat file | sed 's/pattern1/replace_string/g;s/pattern2/replace_string/g'`，
也等同于使用`-e`参数指定多个匹配模式
`cat file | sed -e 's/pattern1/replace_string/g' -e 's/pattern2/replace_string/g'`

sed 命令通常使用单引号来引用，如果要在 sed 命令的表达式中使用变量，则可以使用双引号，shell 在调用 sed 前会先扩展双引号中的内容

### awk 命令

awk 命令可以处理数据流，支持关联数组、递归函数、条件语句等高级功能。

awk 脚本的结构如下：

`awk 'BEGIN { commands } PATTERN { commands } END { commands }' file`，其中 file 也可以是 stdin 中的输入

awk 脚本通常由以上三部分构成：BEGIN、END 以及带模式匹配选项的公共语句块(common statement block)，这三个部分都是可选的，可以不出现在脚本中。

awk 以逐行的形式处理文件。BEGIN 之后的命令先于公共语句块执行，对于匹配 PATTERN 的行，awk 会对其执行 PATTERN 之后的命令，最后，在处理完整个文件之后，awk 会执行 END 之后的命令。

```sh
cat test
# 123
# xxx
# 456
# abc
# 789
# xxx
awk 'BEGIN {i=0} {i++;print i} END {print "total: " i}' test
# 1
# 2
# 3
# 4
# 5
# 6
# total: 6
```

上面的 awk 脚本打印出文件中的行号以及总行数，可以看出，awk 的工作流程为：

1. 首先执行 BEGIN { commands }语句块中的语句，由于 BEGIN 语句块在 awk 开始从输入流中读取行之前被执行，因此通常用来做诸如变量初始化、打印输出表格的表头等等，该语句块也可以被省略
2. 接着从文件或者 stdin 中读取一行，如果能够匹配 PATTERN，则执行后面的 commands，重复这一过程直到全部读取完成
3. 当读至输入流末尾时，执行 END { commands }语句块，END 语句块和 BEGIN 类似，它在 awk 读取完输入流中所有行后才被执行，因此通常用来做一些收尾工作，比如打印数据处理结果，该语句块也可以被省略

awk 最重要的部分是和 PATTERN 相关的语句块，该语句块同样可以被省略，如果省略，awk 默认为每一行执行 print，即打印出所读取的每一行。awk 对读取到的每一行都会执行该语句块，相当于一个 while 循环。每读取一行，awk 就会检查该行是否匹配指定模式，该模式本身可以是正则表达式、条件语句以及行范围等。一旦匹配成功，则执行后面的{ commands }。匹配模式同样也是可选的，如果没有提供匹配模式，则 awk 默认匹配所有行。

> print 命令能够接收参数并打印，这些参数以逗号分隔，在打印参数时则会以空格作为参数之间的分隔。也可以在 print 语句中使用双引号，双引号被当作拼接操作符使用

awk 命令可以使用一些特殊变量：

- NR
  表示记录编号，当 awk 将行作为记录时，该变量相当于当前行号
- NF
  表示字段数量，在处理当前记录时，相当于字段数量，默认的字段分隔符是空格
- $0
  该变量包含当前记录的文本内容
- $1
  该变量包含第一个字段的文本内容
- $2
  该变量包含第二个字段的文本内容
- $N
  该变量包含第 N 个字段的文本内容

> awk 每读取一行，就会自动更新 NR 的值，当到达输入流末尾时，NR 中的值就是最后一行的行号

```sh
cat test
# 123
# xxx
# 456
# abc
# 789
# xxx
awk '{ print $0 } END {print "total: " NR}' test
# 123
# xxx
# 456
# abc
# 789
# xxx
# total: 6
```

`-v`参数可以将外部 z 值(而非来自文件或 stdin)传递给 awk 使用：

```sh
VAR=1000
echo | awk -v VARIABLE=$VAR '{ print VARIABLE }'
# 1000
```

awk 默认读取每一行，如果只想读取某一行，可以在 awk 脚本中使用 getline 函数，通常将其放在 BEGIN 语句块，读取某一行，在进入下一步处理

awk 脚本中还可以使用条件判断来对行进行过滤，例如`awk 'NR < 5'`只读取行号小于 5 的行，`awk 'NR==1,NR==4'`只读取行号在 1 到 5 之间的行

`awk -F delimiter`可以通过参数-F 指定字段分隔符，默认的字段分隔符是空格

awk 中还可以使用关联数组，形如`arrayName[index]`，关联数组是一种使用字符串作为索引的数组

awk 还有一些内建的字符串处理函数：

- length(string)
  返回字符串长度
- index(string,search_string)
  返回 search_string 字符串在字符串 string 中出现的位置
- split(string,array,delimiter)
  以 delimiter 作为分隔符，分割字符串 string，将生成的字符串存入数组 array
- substr(string,start-position,end-position)
  返回字符串中指定起止位置的子串
- sub(regex,replacement_str,string)
  将正则表达式匹配到的第一处内容做替换
- gsub(regex,replacement_str,string)
  和 sub 类似，但是替换所有匹配
- match(regex,string)
  检查正则表达式是否可以在字符串 string 中找到匹配。如果能够找到，返回退出码 0，否则返回非 0 退出码
