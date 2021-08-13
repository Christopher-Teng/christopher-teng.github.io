---
title: Linux命令与shell小技巧(一)
date: 2021-08-11 14:35:06
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

## 基础知识和常用方法

### shebang

shebang，即通常情况下 shell 脚本的第一行，形如：`#!/bin/bash`

其中，/bin/bash 是 Bash 的解释器路径，也可以指定为其他 shell，如/usr/bin/zsh。本行开头的#代表后面是一个注释。这一行的作用是定义了解释该脚本所使用的解释器，脚本中只有第一行可以使用 shebang 语句。

> shebang 这个词其实是两个字符名称(sharp-bang)的简写。在 Unix 中使用 sharp 或 hash 来称呼字符“#”，用 bang 来称呼惊叹号“!”，因而用 shebang 合起来代表这两个字符。

实际使用中，如果我们将脚本作为解释器的命令行参数来使用，那么也可以不使用 shebang，但是当我们独立运行脚本文件时，系统则会使用 shebang 指定的解释器来执行脚本。

### 变量

和大多数脚本语言一样，shell 脚本可以直接使用赋值操作符(=)来定义变量而不需要声明类型，使用美元符号($)来使用变量。

> shell 中变量名由字母、数字、下划线组成，其中不包含空白字符，常用的惯例是使用大写字母命名环境变量，使用驼峰命名法或者小写字母命名其他变量
>
> `fruit=apple`定义变量，$fruit和${fruit}都可以使用变量，当形如 echo "${fruit}(s)"的时候，使用花括号的方式可以准确指定变量名称
>
> 对于单引号和双引号的区别，单引号不会扩展变量，即`echo '$fruit'`将显示$fruit，而双引号会扩展变量，即`echo "$fruit"`将显示 apple
>
> 使用形如`${#var}`可以获得变量的长度，例如`echo "${#fruit}"`将会显示 5

shell 定义了一些变量用于保存用到的配置信息，例如可用的打印机、搜索路径等，这些变量称为**环境变量**，可以使用 env 或者 printenv 命令查看当前 shell 中定义的全部环境变量。

> 使用环境变量`$SHELL`可以获知当前使用哪一种 shell，例如`echo "$SHELL"`显示/usr/bin/bash，也可以使用`echo "$0"`获得同样的结果
>
> 通过修改 shell 配置文件(例如.bashrc)里面的环境变量`$PS1`可以改变 shell 默认的提示字符串

通过 shell 可以对变量进行简单的数学运算，下面是几个例子：

```sh
n1=3
n2=7

let res1=n1+n2 # 加号之间没有空格
res2=$[ n1 + n2 ]
res3=$(( n1 + n2 ))
res4=`expr $n1 + $n2`

echo -e "n1: $n1,n2: $n2\nres1: $res1\nres2: $res2\nres3: $res3\nres4: $res4"

# n1:3,n2:7
# res1: 10
# res2: 10
# res3: 10
# res4: 10
```

以上方法只能计算整数值，如果要计算浮点值，可以使用 bc，例如：

```sh
echo "4 * 0.56" | bc
# 2.24
x1=54
x2=1.5
res=`echo "$x1 * $x2" | bc`
echo "$res"
# 81.0
```

<!-- more -->

> echo 命令
> echo 用于终端打印，每次调用后会添加一个换行符，可以使用-n 参数来禁止这种行为。使用-e 参数则可以将转义序列正确输出。echo 后面需要打印的内容，可以放入双引号、单引号、反引号中，也可以不使用引号。由于分号在 shell 中用作命令分隔符，因此不使用引号的时候，无法打印分号；放入单引号中的内容不会转移，变量不会扩展；放入双引号中的内容会被转移、变量会被扩展，因此特殊字符前需要使用反斜杠(\)；放入反引号中的内容，会开启子 shell 执行当中的命令。
>
> printf 命令
> printf 也可以用于终端打印，其参数和 C 语言中的 printf 函数一样。可以在 printf 中使用格式化字符串来指定字符串的宽度、左右对齐方式等。默认情况下 printf 不会自动添加换行符，需要手动添加。%s、%c、%d、%f 都是格式替换符。形如%-5s 中，-代表左对齐，不指定则默认为右对齐，5 指定保留字符串宽度为 5 个字符，不足则以空格填充。形如%4.2f 中.2 指定保留 2 位小数，总共保留 4 位。

### 文件描述符与重定向

文件描述符是与某个打开的文件或数据流相关联的整数，系统预留的文件描述符为 0、1、2，分别代表：

- 0 —— stdin(标准输入)
- 1 —— stdout(标准输出)
- 2 —— stderr(标准错误)

  `>`用于向文件中写入，会覆盖已有内容，`>>`则是向文件追加内容。当一条命令执行失败时，会返回一个非 0 的退出状态，而当命令成功执行后，会返回为 0 的退出状态，退出状态可以从特殊变量$?获得。当命令执行失败后，错误信息默认会输出到 stderr，可以通过`2>`或`2>>`将 stderr 重定向到文件中，而使用`2>&1`则可以同时重定向 stdout 和 stderr。o

  > 特殊设备文件/dev/stdin、/dev/stdout、/dev/stderr 分别对应 stdin、stdout、stderr，还有一个**黑洞**，凡是进入的数据都将一去不复返，这就是/dev/null，这也是一个特殊设备文件，它会丢弃接受到的任何数据。

  `<`可以像 stdin 那样从文件中读取数据。

### 数组与关联数组

- 定义数组：

  - 在单行中使用数值列表进行定义，这些值会存储在以 0 为起始索引的连续位置上。

    ```sh
    array_var=(test1 test2 test3)
    ```

  - 也可以将数组定义为一组“索引-值”：

    ```sh
    array_var[0]="test1"
    array_var[1]="test2"
    array_var[2]="test3"
    ```

- 打印出特定索引的数组元素内容：

  ```sh
  echo ${array_var[0]}
  # test1
  index=2
  echo ${array_var[$index]}
  # test3
  ```

- 以列表形式打印出数组中的所有值：

  ```sh
  echo ${array_var[*]}
  # test1 test2 test3
  echo ${array_var[@]}
  # test1 test2 test3
  ```

- 打印数组长度(元素个数)：

  ```sh
  echo ${#array_var[*]}
  # 3
  ```

- 定义关联数组

  在关联数组中，可以使用任意文本作为数组索引。要定义关联数组，首先需要将一个变量声明为关联数组：

  ```sh
  declare -A fruits_value
  ```

  - 使用行内“索引-值”列表：

    ```sh
    fruits_value=([apple]='100 dollars' [orange]='150 dollars')
    ```

  - 使用独立的“索引-值”进行赋值：

    ```sh
    fruits_value[apple]='100 dollars'
    fruits_value[orange]='150 dollars'
    ```

- 关联数组的其他操作方法则与普通数组一样，只需要将数字索引改为使用文本索引即可

### 别名

别名提供了一种便捷的方式来调用命令，省去了输入一长串命令的麻烦。别名通过`alias`创建，例如`alias lsa="ls -alhF"`，别名的效果是暂时的，通过将别名定义放入 shell 配置文件中(例如.bashrc)可以使别名长期生效。当创建别名时，如果有同名的别名存在，则旧的别名会被覆盖。要删除别名，可以使用`unalias`，也可以通过使用如`alias lsa=`的方式取消。单独使用`alias`命令可以显示当前所有别名，后面跟上别名名称，则可以显示对应别名的内容。

### 时间

使用`date`命令可以读取和设置时间。使用-s 参数用于设置指定时间；使用带有前缀+的格式化字符串的参数则可以按指定格式打印出当前时间；使用+%s 可以得到 Unix 纪元时。

> _tips_：date 命令的最小单位是秒，如果要对命令计时，因该使用 time 命令
>
> Unix 纪元时被定义为从世界标准时间 UTC，1970 年 1 月 1 日 0 时 0 分 0 秒起至当前时刻的总秒数，不包含闰秒。

下面列出 date 命令支持的格式化字符串参数：

- %y -- 年，例如：21
- %Y -- 年，例如：2021
- %b -- 月，例如：Nov
- %B -- 月，例如：November
- %d -- 日，例如：11
- %D -- 特定格式日期(mm/dd/yy)，例如：08/11/21
- %a -- 工作日(weekday)，例如：Sat
- %A -- 工作日(weekday)，例如：Saturday
- %H -- 时，例如：08
- %M -- 分，例如：33
- %S -- 秒，例如：17
- %N -- 纳秒，例如：660561200
- %s -- Unix 纪元时，以秒为单位，例如：1628694257

`sleep`命令可以设置延迟时间，以秒为单位，例如以下脚本可以间隔 3 秒输出"Hello World!"：

```sh
#! /bin/bash
for count in `seq 1 3`
do
  echo "Count: $count -- Hello World!"
  sleep 3
done

# Count: 1 -- Hello World!
# 间隔3秒
# Count: 2 -- Hello World!
# 间隔3秒
# Count: 3 -- Hello World!
# 间隔3秒，脚本执行完成
```

> 上面脚本中，<code>for count in `seq 1 3`</code>也可以写成`for count in (1..3)`，这个语言构件执行速度比 seq 命令略快

### 函数

1. 定义函数

   函数的定义包括 function 命令、函数名、一对圆括号以及使用一对花括号包含的函数体。

   ```sh
   function fname()
   {
     statements;
   }
   ```

2. 调用函数

   直接使用函数名就可以实现函数调用。

   ```sh
   fname;
   ```

   函数支持递归调用，必须注意递归调用一定要有退出条件，否则将导致系统资源耗尽或崩溃。

   > Fork 炸弹，该函数会在后台不断的衍生出新进程
   > `: () { : | :& };:`

3. 参数

   - $0 脚本名
   - $1、$2、...$n 脚本第 1 个参数、第 2 个参数...第 n 个参数
   - $* 脚本所有参数，被扩展成"$1c$2c...$n"，其中 c 为 IFS 的第一个字符
   - $@ 脚本所有参数，以列表形式扩展，"$1" "$2" ... "$n"

   > `$@`要比`$*`用得多，因为`$*`将所有参数扩展成一个字符串

   大多数应用都能接受不同的参数执行相应的操作，可以通过使用`shift`命令来实现。该命令可以将参数依次往左移动一位，这样就可以循环使用`$1`来取得所有参数。

4. 返回值

   在函数体中使用`return`语句返回值，返回值被称为退出状态，按照惯例，函数成功执行完毕，应该返回 0 作为退出状态，否则因该返回一个非 0 值。退出状态可以通过特殊变量`$?`取得。

5. 导出函数

   可以使用`export -f fname`到处函数，这样函数的作用域就可以被扩展到子 shell 中。

### 管道

Unix shell 最棒的特性就是可以轻松的将多个命令组合起来完成复杂的任务，一个命令的输出作为下一个命令的输入，依次传递。这种情况下，这些命令称为过滤器 filter，使用管道 pipe 可以将每个过滤器连接起来。

```sh
cmd1 | cmd2 | cmd3
```

通过管道配和子 shell 的方式，我们可以从多个命令组合取得结果，例如：

```sh
ls | cat -n > out.txt
# 列出当前目录的内容并且加上行号，结果将存入out.txt文件
```

另一种实现方式：

```sh
cmd_out=$(ls | cat -n)
echo $cmd_out
```

还有一种实现方式：

```sh
cmd_output=`ls | cat -n`
echo $cmd_output
```

以上几种方式都可以获得组合命令的结果，其中第二种采用的就是子 shell，通过`$()`可以生成一个子 shell，子 shell 是一个独立的进程，因此当命令在子 shell 中执行时，不会对当前 shell 造成影响，例如在子 shell 中使用`cd`命令切换目录，不会改变当前 shell 中的工作目录。

如果要将反引号或子 shell 方式获得的结果保存到变量或文件中，需要注意结果中的空格和换行符要通过使用双引号来保留，例如：

```sh
cat test.txt
# 1
# 2
# 3
out=$(cat test.txt)
# 1 2 3
# 丢失换行符
res="$(cat test.txt)"
# 1
# 2
# 3
# 正确保留了换行符
```

### 从键盘或标准输入读取

`read`命令可以让程序从键盘或标准输入读取数据：

- read -n char_number var 读取 n 个字符并存入变量
- read -s var 使用无回显的方式读取输入存入变量
- read -p "message" var 给出提示信息
- read -t timeout var 限定有效输入时间(秒)
- read -d delimiter_char var 使用指定的定界符从输入中读取数据存入变量，使用这种方法可以让我们不必按回车键也可以录入数据

### 持续运行命令直至成功

```sh
repeat () {
  while true
  do
    $@ && return
  done
}
```

该函数通过一个死循环反复调用以函数参数形式($@)传入的命令，直到命令成功执行，才会退出循环。

> 上面的函数定义中，可以把`while true`替换成`while :;`，其中`:;`是 shell 内建命令，总是返回 0 作为退出状态，性能比使用 true 要好

### IFS

IFS，即内部字段分隔符，它是一个环境变量，其中保存了用于分隔的字符，它是当前 shell 环境默认使用的定界字符串。在处理字符串或者逗号分隔型数值(csv)是很有用，IFS 默认值是空白字符(换行符、空格或制表符)。我们可以这样来使用：

```sh
oldIFS=$IFS
IFS=, # 以逗号作为分隔符
while condition
do
  echo "do something"
done
IFS=$oldIFS
```

### 比较与测试

1. if

   ```sh
   if condition
   then
     commands
   fi
   ```

2. if...else

   ```sh
   if condition
   then
     commands
   else if condition
   then
     commands
   fi
   ```

3. &&和||

   ```sh
   [ condition ] && action # 如果condition为真，执行action
   [ condition ] || action # 如果condition为假，执行action
   ```

4. test 命令

   `test`命令同样可以用来测试条件，通过调用 test 命令可以避免条件判断时使用过多的括号，增强代码可读性。另一方面，test 作为一个外部命令，使用时会衍生出对应的进程，而括号是 Bash 内建的函数，执行效率比 test 命令更高。
