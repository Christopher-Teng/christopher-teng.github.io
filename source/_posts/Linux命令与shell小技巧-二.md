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

## 常用命令

### cat 命令

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

还可以使用cat命令将stdin的输入写入文件(>或>>)，使用类似下面的格式：
```sh
cat << EOF > file
input something...
EOF
```

### find 命令

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

### xargs 命令

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

### tr 命令

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

`tr -s [重复的一组字符]`可以删除字符串中重复出现的指定字符：

```sh
cat test
# some   messages     here
cat test | tr -s ' '
# some messages here
cat test1
# some
#
#
# messages
#
#
#
#
#
# here
cat test1 | tr -s '\n'
# some
# messages
# here
```

### sort 命令

sort 命令可以从特定文件或 stdin 中获取输入，并按指定方式排序后输出到 stdout。

`sort file1 file2 file3`可以对一组文件进行排序

`sort -n file`可以按照数字顺序进行排序

`sort -r file`按照逆序排序

`sort -M file`按照月份排序(一月、二月、三月...)

`sort -m sorted1 sorted2`合并两个已经排序过的文件

`sort -c file`检查文件是否已经排序，如果已经排序则返回为 0 的退出码，否则返回一个非 0 退出码

`sort -k number file`可以按指定列进行排序，如果是单个数字则表示列号，如果是形如`1.3,1.4`则表示区间范围(第一列第三个字符)：

```sh
cat -n test
# 1 some
# 2 messages
# 3 here
cat -n test | sort -nrk 1
# 3 here
# 2 messages
# 1 some
cat -n test | sort -k 2.4,2.5
# 1 some
# 3 here
# 2 messages
```

`sort -z`，通过-z 参数可以把 sort 的输出传递给 xargs 使用(指定-0)，这样可以避免因为含有空白字符出现错误

### uniq 命令

uniq 命令可以从给定文件或 stdin 中读取数据，从中找出唯一的行，报告或删除那些行。uniq 只能作用于排过序的数据，因此通常和 sort 命令搭配使用。

`sort file | uniq`会打印文件内容，但是重复的内容只显示一次

`sort file | uniq -u`只显示文件中唯一的行

`sort file | uniq -c`统计文件中各行出现的次数

`sort file | uniq -d`找出文件中重复的行

`uniq -s n -w m`会跳过每行的前 n 个字符，然后使用最多 m 个字符进行比较：

```sh
cat test
# u:01:gnu
# d:04:linux
# u:01:bash
# u:01:hack
sort test | uniq -s 2 -w 2 -c
# 1 d:04:linux
# 3 u:01:bash
# -s 2跳过每行前两个字符，-w 2以接下来的2个字符进行重复判断，即每行中的2位数字，-c统计重复次数
# 虽然同为u:01:开头的3行内容并不相同，但是这里指定了以每行中的2位数字进行判断，所以统计为u:01:出现了3次
```

`uniq -z`，通过-z 参数，可以将 uniq 的输出传递给 xargs 使用(指定-0)，这样可以避免因为空白字符出现错误

### mktemp 命令

`filename=$(mkdtemp)`可以创建临时文件，并将文件名存入变量

`dirname=$(mktemp -d)`可以创建临时目录，并将目录名存入变量

`mktemp -u`只生成临时文件名，但不创建实际文件或目录

### %、%%、#和##操作符

`${VAR%.*}`从字符串中删除位于%右侧的通配符所匹配的所有字符，通配符从右向左匹配。%属于非贪婪(non-greedy)操作，而%%属于贪婪匹配：

```sh
file_jpg='sample.jpg'
echo ${file_jpg%.*}
# sample
filename='back.fun.book.txt'
echo ${filename%.*}
# back.fun.book
echo ${filename%%.*}
# back
```

`${VAR#*.}`和%效果相反，只不过会删除位于#左边通配符匹配到的所有字符，匹配方向为从左向右，同样的，#为非贪婪匹配，##为贪婪匹配。

```sh
echo $file_jpg
# sample.jpg
echo ${file_jpg#*.}
# jpg
echo filename
# back.fun.book.txt
echo ${filename#*.}
# fun.book.txt
echo ${filename##*.}
# txt
```

%、%%、#、##常用来分隔文件名和文件扩展名，也可以用来分隔 URL 地址获取协议、域名、主机名等等。

> 考虑到文件名中可能含有多个.，因此提取文件扩展名时更多的是使用##进行贪婪匹配

批量重命名文件：

```sh
ls
# back.jpg fun.png book.jpg
cat rename.sh
# count=1
# for img in `find . -maxdepth 1 -type f -iname '*.jpg' -o -iname '*.png'`
# do
#     new=IMG-$count.${img##*.}
#     echo "Rename $img to $new"
#     mv $img $new
#     let count++
# done
. ./rename.sh
ls
# IMG-1.png IMG-2.jpg IMG-3.jpg
```

### parallel 命令

parallel 命令从 stdin 中读取文件列表，用类似 find 的-exec 或者 xargs 的方式来使用指定命令处理文件，其中{}替代要处理的文件名，{.}替代无扩展名的文件名。parallel 命令可以优化系统资源使用，在同时处理大量文件时，可以避免系统过载。

```sh
ls
# test1.txt test2.txt test3.txt
cat test1.txt test2.txt test3.txt
# test 1
# test 2
# test 3
find . -type f -name 'test*' | parallel cat {}
# test 1
# test 2
# test 3
find -type f -name 'test*' | parallel mv {} {.}New.txt
ls
# test1New.txt test2New.txt test3New.txt
```

## 文件操作

### dd 命令

dd 命令会克隆给定的输入内容，然后将一模一样的一份副本写入输出。stdin、设备文件、输入文件等都可以作为输入，stdout、设备文件、普通文件等也可以作为输出。

`dd if=/dev/zero of=file bs=1M count=1`会生成一个内容为空的 1M 大小的文件。其中，if 代表输入(input file)，/dev/zero 是一个特殊的字符设备，会返回 0 值字节(\0)；of 代表输入(output file)，bs 代表以字节为单位的块大小(block size)，count 代表需要被复制的块数量。如果将命令中的 bs 改为 2M，count 改为 2，则会生成一个内容为空的 4M 大小的文件。如果省略 if 则会从 stdin 读取输入，而省略 of 则会将结果输出到 stdout。

bs 支持的单位如下：

- c 字节(B)
- w 字(2B)
- B 块(512B)
- K 千字节(1024B)
- M 兆字节(1024KB)
- G 吉字节(1024MB)

### chmod 命令

`chmod u=rwx g=rwx o=rwx filename`使用 u(User)、g(Group)和 o(Other)分别为用户、用户组和其他用户设置权限

`chmod a+x`为所有用户添加执行权限

`chmod a-x`为所有用户删除执行权限

`chmod 777`为所有用户设置读写执行权限(r=4 w=2 x=1)

`chmod 777 . -R`对当前目录递归的设置读写执行权限

### chown 命令

`chown user:group filename`修改文件所属用户和用户组

`chown user:group . -R`对当前目录递归的设置用户和用户组

### touch 命令

`touch filename`可以生成空白文件

```sh
for name in {1...100}.txt
do
  touch $name
done
```

批量生成名字为 1.txt 到 100.txt 的空白文件。如果文件不存在则会新创建文件，如果文件已经存在，则会将文件的所有时间戳更新为当前时间。可以通过参数`-a`只更新访问时间、参数`-m`只更新修改时间、参数`-d`可以将时间戳修改为指定时间而不是当前时间。

### ln -s 命令

ln -s 命令用来创建符号链接，类似 windows 的快捷方式，格式为：

`ln -s target symbolic_link_name`

### 环回文件

Linux 文件系统通常位于磁盘或 U 盘上，但其实文件也可以作为文件系统进行挂在，这种存在于文件中的文件系统可用于测试、文件系统定制或者作为机密信息的加密盘。

下面在一个大小为 1GB 的文件中创建 ext4 文件系统并进行挂在：

1. 使用 dd 命令创建一个 1GB 大小的文件

   `dd if=/dev/zero of=loopbackfile.img bs=1G count=1`

2. 用 mkfs 命令将 1GB 的文件格式化为 ext4 文件系统

   `mkfs.ext4 loopbackfile.img`

3. 使用 file 命令检查文件系统

   `file loopbackfile.img`

4. 使用 mkdir 创建挂载点并挂载环回文件

   `mkdir /mnt/loopback && mount -o loop loopbackfile.img /mnt/loopback`

   选项`-o loop`用来指定挂载环回文件

5. 使用下面的方式卸载

   `umount /mnt/loopback`

### diff 命令

diff 命令可以用来比较两个文件之间的差异，也可以利用修补文件(patch file)将两个文件同步。

`diff -u version1 version2`显示两个文件之间的差异，选项`-u`指定输出为一体化显示，更易于阅读。

`diff -u version1 version2 > version.patch`生成修补文件

`patch -p1 version1 < version.patch`使用修补文件修补 version1 使 version1 与 version2 文件一致，修补之后再次使用同样的方式进行修补则会撤销之前的修补。

`patch -p2 version2 < version.patch`则使用修补文件修补 version2 使 version2 与 version1 文件一致，再次使用同样的方式修补则会撤销之前的修补。

### head 和 tail 命令

`head file`读取文件前 10 行进行显示，参数`-n`可以指定要显示的行数，如果行数是一个负数，则打印除指定行以前的所有行

`tail file`读取文件的最后 10 行进行显示，参数`-n`可以指定要显示的行数，如果行数指定为形如`+M`的模式，则显示除 M-1 行(从第 M 行到结尾)的所有行。

`tail -f file`会监视文件的增长并将更新内容显示出来，该用法常常用于跟踪日志文件。

### pushd 和 popd 命令

pushd 和 popd 可以用来替代 cd 命令，这对命令用于在多个目录之间切换而无需重新输入目录路径，这两条命令会创建一个路径栈，该路径栈是一个保存了已访问目录的 LIFO(Last In First Out，后进先出)列表。

```sh
dirs  # 显示已访问目录路径栈内容
# ~
pushd ./Documents  # 压入并切换路径
dirs
# ~/Documents ~
pushd ./test
dirs
# ~/Documents/test ~/Documents ~
pushd +0  # 切换目录并更新已访问目录路径栈
dirs
# ~ ~/Documents/test ~/Documents
# pushd总是向路径栈中压入目录
popd  # 删除最近压入的路径并切换到下一个目录
dirs
# ~/Documents/test ~/Documents
popd +0  # 删除路径栈中特定的路径
dirs
# ~/Documents/test
```

### wc 命令

`wc -l file`统计文件中的行数

`wc -w file`统计单词数

`wc -c file`统计字符数

```sh
echo '1234' | wc -c
# 5
echo -n '1234' | wc -c
# 4
# echo默认添加换行符，-n参数指定不添加
```

`wc file`不指定参数时，会同时打印出行数、单词书和字符数

`wc -L file`打印出文件中最长一行的长度

```sh
echo -e '1\n12\n123\n1234\n12345' | wc
# 5 5 20
echo -e '1\n12\n123\n1234\n12345' | wc -L
# 5
```

### tree 命令

tree 命令可以用图形化树状结构打印出文件和目录。

`tree path -P PATTERN`可以只显示匹配指定模式的文件

`tree path -I PATTERN`可以只显示不匹配指定模式的文件

`tree -h`可以同时打印出文件和目录的大小
