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

`grep --color=auto "pattern" file`在输出中着重标记出匹配到的模式，选项--color 对在命令中的放置位置没有强制要求，但是通常作为第一个选项出现

`grep -E "[a-z]+" file`或者`egrep "[a-z]+" file`使用扩展的正则表达式进行搜索，而 grep 默认使用基础正则表达式

`grep -o "pattern" file`只输出匹配到的文本

`grep -v "pattern" file`输出不匹配的所有行

`grep -c "pattern" file`统计成功匹配的文本行数，加上选项`-v`可以反转匹配结果，统计不匹配的文本行数

> 使用`-c`选项只是统计出成功匹配的文本行数，而不是匹配的次数，如果要统计匹配的次数，可以使用如下的技巧：
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

`grep "pattern" path -R --include "pattern"`可以在搜索过程中用通配符指定某些文件，相反的，选项`--exclude`在搜索过程中使用通配符排除某些文件，`--exclude-dir`可以排除目录

`grep -Z "pattern" file`可以使用 0 值字符(\0)作为文件名的终结符，结合选项`-l`或`-L`可以搜索出特定文件，然后传递给 xargs 执行下一步操作：

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

选项`&`指代模式所匹配到的字符串：

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

选项`\N`用来指代第 N 个子模式(出现在括号中的正则表达式)匹配的结果：

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
也等同于使用`-e`选项指定多个匹配模式
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

> print 命令能够接收选项并打印，这些选项以逗号分隔，在打印选项时则会以空格作为选项之间的分隔。也可以在 print 语句中使用双引号，双引号被当作拼接操作符使用

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

`-v`选项可以将外部 z 值(而非来自文件或 stdin)传递给 awk 使用：

```sh
VAR=1000
echo | awk -v VARIABLE=$VAR '{ print VARIABLE }'
# 1000
```

awk 默认读取每一行，如果只想读取某一行，可以在 awk 脚本中使用 getline 函数，通常将其放在 BEGIN 语句块，读取某一行，在进入下一步处理

awk 脚本中还可以使用条件判断来对行进行过滤，例如`awk 'NR < 5'`只读取行号小于 5 的行，`awk 'NR==1,NR==4'`只读取行号在 1 到 5 之间的行

`awk -F delimiter`可以通过选项-F 指定字段分隔符，默认的字段分隔符是空格

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

### paste 命令

paste 命令可以按列合并文件，并且可以使用选项`-d`指定输出分隔符，默认的分隔符是制表符(\t)，选项`-s`可以先将所有列合并成单行在合并连个文件

```sh
cat test1
# 123
# xxx
# 456
# abc
# 789
# xxx
cat test2
# xxx
# 789
# abc
# 456
# xxx
# 123
paste -s -d , test1 test2
# 123,xxx,456,abc,789,xxx
# xxx,789,abc,456,xxx,123
paste test1 test2
# 123     xxx
# xxx     789
# 456     abc
# abc     456
# 789     xxx
# xxx     123
```

### ${variable_name:start_position:length} 文本切片

我们可以通过指定文本字符串起始位置和截取长度，从文本字符串中生成子串：

```sh
echo $test
# xxx
# 789
# abc
# 456
# xxx
# 123
echo ${test:4:3}
# 789
echo ${test:4:-4}
# 789
# abc
# 456
# xxx
```

## 从网络获取数据

### wget 命令

wget 命令可以下载网页或者远程文件。

`wget URL`从指定网址下载页面，或者`wget URL1 URL2 URL3 ...`从多个 URL 处下载

`wget URL -O filename`可以指定下载后文件的名字，如果存在同名文件，则原文件会被下载文件覆盖

`wget URL -o log`则可以指定将日志或进度信息写入指定日志文件，而不输出到 stdout

`wget -t time URL`可以指定下载失败时，进行多少次尝试再放弃下载，如果设为 0 即强制不断的尝试下载直到下载完成

`wget --limit-rate rate URL`可以对下载进行限速，单位可以使用千字节(K)和兆字节(m)

`wget -Q quota URL`可以限制下载最大配额，单位同样支持千字节(k)和兆字节(m)，一旦下载大小超出限额则放弃下载

`wget -c URL`可以对下载完成前被中断的下载进行断点续传

`wget --user username --password password URL`可以用于需要进行认证的网站

### curl 命令

curl 命令可以使用 HTTP、HTTPS、FTP 协议在客户端和服务器之间传递数据，支持 POST、cookie、认证、从指定偏移处下载部分文件、参照页(referer)、用户代理字符串、扩展头部、限速、文件大小限制、进度条等特性。常用于网站维护、数据检索以及服务器配置核对。

curl 默认将下载文件输出到 stdout，将进度信息输出到 stderr，可以使用选项`--silent`关闭进度显示。

`curl URL`将下载信息输出到 stdout

`curl URL --silent -O`关闭进度输出，并且通过选项`-O`将下载数据写入文件，文件名采用从 URL 中解析出的文件名，因此这里的 URL 必须是完整的(www.example.com/index.html)，而不是仅有站点域名

`curl URL -o filename`则可以用指定文件名来存储下载数据，因此此处的 URL 可以只是站点的域名

`curl URL --progress`可以在下载过程中显示形如**#**的进度条

`curl URL -C offset`可以进行断点续传，需要指明偏移量，将 offset 写为`-`则可以让 curl 自动计算因该从哪里开始续传

`curl --referer Referer_URL target_URL`可以指定参照页，只有 HTTP 头部字段中**参照页(Referer)**符合指定地址时，才会从目标地址进行下载

`curl URL --cookie "key1=value1;key2=value2"`可以指定和存储下载过程中产生的 cookie

`curl URL --cookie-jar cookie_file`可以将所有 cookie 存入文件

`curl URL --user-agent UA`或者`curl URL -A UA`可以设置用户代理字符串

`curl -H "key:value" -H "key:value" URL`可以发送多个 HTTP 头部(header)信息

`curl URL --limit-rate rate`可以限速，用法和 wget 一样

`curl URL --max-filesize size`可以限额，用法和 wget 一样，如果大小超出限额，则命令返回非 0 退出码，否则返回 0 退出码

`curl -u username:password URL`可以进行认证，用法和 wget 一样

`curl -I URL`或者`curl --head URL`可以只下载头部信息而不下载完整的页面

### 网络图片爬取及下载

下面综合利用上述命令，编写一个网络图片爬取及下载的脚本：

```sh img_downloader.sh
#!/bin/bash
# 用途：图片下载工具
# 文件名： img_downloader.sh
if [ $# -ne 3 ]
then
  echo "Usage: $0 URL -d DIRECTORY"
  exit -1
fi

while [ $# -gt 0 ]
do
  case $1 in
  -d) shift; directory=$1; shift ;;
  *) url=$1; shift ;;
  esac
done

mkdir -p $directory;
baseurl=$(echo $url | egrep -o "https?://[a-z.\-]+")

echo Downloading $url
curl -s $url | egrep -o "<img[^>]*src=[^>]*>" | \
  sed 's/<img[^>]*src=\"\([^"]*\).*/\1/g' | \
  sed "s,^/,$baseurl/," > /tmp/$$.list

cd $directory;

while read filename;
do
  echo Downloading $filename
  curl -s -O "$filename"
done < /tmp/$$.list
```

### 网页相册生成器

Web 开发中经常会创建包含全尺寸和缩略图的相册。点击缩略图，就会出现一幅放大的图片。如果需要很多图片，每一次都得复制`<img>`标签、调整图片大小来创建缩略图、把调整好的图片放进缩略图目录。我们可以写一个简单的 Bash 脚本将这些重复工作自动化，这样一来，创建缩略图、将缩略图放入对应目录、生成`<img>`标签都可以自动搞定。

```sh generate_album.sh
#!/bin/bash
# 文件名：generate_album.sh
# 用途：用当前目录下的图片创建相册

echo "Creating album..."

currentDir=`pwd`
albumName=${currentDir##*/}

mkdir -p thumbs
cat <<EOF1 > index.html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,minimum-scale=1,user-scalable=no" >
<meta name="X-UA-Compatible" content="IE=edge,chrome=1" >
<style>
  body{
    margin:auto;
    padding:0 10px;
    background-color: darkcyan;
    border:1px dashed grey;
  }

  h1{
    position:fixed;
    top:0;
    margin:0;
    padding:10px 0;
    width:100%;
    height:30px;
    line-height:30px;
    text-align:center;
    color:white;
    background-color:darkcyan;
    z-index:999;
  }

  main{
    display:flex;
    flex-flow:row wrap;
    justify-content:space-between;
    align-items:center;
    margin-top:50px;
  }

  img{
    margin:0 5px 10px;
    border:1px solid black;
    box-shadow:2px 2px 2px 1px white;
  }

  img:hover{
    transform:scale(1.1);
  }
</style>
<title>$albumName</title>
</head>
<body>
  <h1>Photo Album $albumName </h1>
  <main>
EOF1

for img in `ls $currentDir | egrep '*.(jpg|png)'`
do
  convert "$img" -resize "100x" "thumbs/$img"
  echo "<a href=\"$img\" >" >> index.html
  echo "<img src=\"thumbs/$img\" title=\"$img\" /></a>" >> index.html
done

cat <<EOF2 >> index.html
</main>
</body>
</html>
EOF2

echo Album generated to index.html
```

## 归档、压缩与备份

### tar 命令

tar 命令可以用来归档文件，它最初是用来将数据存储在磁带上的，因此其名字来源于
Tape ARchive。tar 可以将多个文件或文件夹打包成单个文件，同时还能保留所有文件属性，如所有者、权限等，由 tar 创建的文件通常称为 tarball。

`tar -cf ARchive.tar SOURCES`将指定目标打包成指定归档文件名的 tarball，其中选项`-c`表示创建归档文件，选项`-f`指定归档文件名，文件名必须紧跟在选项`-f`后面

`tar -tf ARchive.tar`列出归档中的文件

`tar -cvf ARchive.tar SOURCES`，选项`-v`表示冗长模式，即在命令执行过程中输出细节信息，还可以使用选项`-vv`(非常冗长模式)

`tar -rvf ARchive.tar new_file`可以向归档文件末尾追加新文件

`tar -xvf Archive.tar`可以从归档文件中提取内容到当前目录，还可以加上选项`-C PATH`提取到指定位置

可以在 tar 命令中使用 stdin 和 stdout，下面的命令可以将本地数据先归档然后在通过 SSH 传输到远程并且提取到指定位置：

`tar -cvf - SOURCES | ssh user@host "tar -xv -C PATH`

`tar -Af archive1.tar archive2.tar`可以将 archive2.tar 中的内容合并到 archive1.tar 中

`tar -uf ARchive.tar new_file`可以向归档文件中追加新文件，和使用选项`-r`不同，选项`-u`指定只有当 new_file 比归档中同名文件更新时才会执行追加操作，否则什么都不会发生，而选项`-r`则一定会执行追加操作，因此归档中可能出现完全相同的两个同名文件

`tar -df ARchive.tar`可以将归档中的内容和文件系统中的内容做比较，可以利用这条命令确定是否需要追加新的文件

`tar -f ARchive.tar --delete file1 file2 ...`可以从归档中删除文件

tar 命令默认只进行归档而不执行文件压缩，但是提供压缩选项来开启压缩功能：

- -z 指定开启 gzip 压缩，输出格式为 archive.tar.gz 或 archive.tgz
- -j 指定开启 bzip2 压缩，输出格式为 archive.tar.bz2
- --lzma 指定开启 Lempel-Ziv-Markov 压缩，输出格式为 archive.tar.lzma

也可以使用选项`-a`让 tar 命令根据指定的压缩归档文件扩展名选择合适的压缩方式

`tar -cvf ARchive.tar SOURCES --exclude PATTERN`可以将匹配指定模式的文件排除在归档之外，也可以将要排除的文件列表放入文件中，然后使用选项`-X`从文件中读取排除内容

`tar --exclude-vcs -cvf ARchive.tar SOURCES`可以将版本控制目录排除在归档之外

`tar -cvf ARchive.tar SOURCES --totals`可以在完成归档后显示归档的总字节数，注意如果启用了压缩，实际的压缩归档文件大小会小于显示的这个总字节数

### zip、unzip 命令

ZIP 作为一种流行的压缩格式，在 Mac、Windows 和 Linux 平台下都可以使用，虽然在 Linux 中它的使用率不及 gzip，但是当我们需要向其他平台分发数据时，使用 zip 非常有用。

`zip ARchive_name.zip file1 file2 ...`进行压缩归档

`zip -r ARchive_name.zip folder1 folder2 ...`可以递归的对目录进行压缩归档

`zip ARchive_name.zip -u newfile`可以更新压缩归档中的文件

`zip -d ARchive_name.zip file1 file2 ...`从压缩归档文件中删除内容

`unzip ARchive_name.zip`提取内容

`unzip -l ARchive_name.zip`列出压缩归档文件中的内容

### squashfs 命令

squashfs 程序可以创建出一种具有超高压缩比的只读型文件系统，它可以将 2GB~3GB 的数据压缩成一个 700MB 左右的文件。Linux LiveCD(或者 Linux LiveUSB)就是使用 squashfs 创建的，这类 CD(USB)利用只读型的压缩文件系统，将根文件系统保存在一个压缩文件中，然后使用环回文件的方式进行挂载，从而装入完成的 Linux 系统。如果需要某些文件，可以将其解压然后装入内存中使用。解压缩体积较大的压缩文件很费时，但是将其通过环回方式进行挂在，那速度会变得飞快，因为只有出现访问请求时，才会解压缩相应的文件。

创建 squashfs 需要使用 squashfs-tools，可以使用包管理器来安装。

首先使用 mksquashfs 命令添加源目录和文件，创建一个 squashfs 文件：

`mksquashfs SOURCES compressedfs.squashfs`

然后利用环回形式挂在 squashfs 文件：

```sh
mkdir /mnt/squash
mount -o loop compressedfs.squashfs /mnt/squash
```

> 创建 squashfs 文件时，可以通过`mksquashfs -e`排除指定目录，或者将排除列表放入文件，然后使用选项`-ef`读取

### rsync 命令

rsync 命令可以用于本地和远程的数据备份，它可以在最小化数据传输量的同时，同步不同位置上的文件和目录。和 cp 命令相比，rsync 会比较文件修改时间，仅复制较新的文件，而且还支持远程数据传输、压缩和加密。

`rsync -av SOURCE_PATH DESTINATION_PATH`，该命令可以同步源路径和目标路径的数据，选项`-a`表示进行归档操作，选项`-v`表示在 stdout 上输出细节信息或进度，其中源路径和目标路径既可以是本地位置也可以是远程位置

`rsync -avz SOURCE_PATH DESTINATION_PATH`使用选项`-z`指定开启压缩，这样可以明显改善传输效率

使用选项`--exclude`可以在备份数据时指定排除的数据，或者使用选项`--exclude-from`从文件中读取排除内容

默认情况下，rsync 不会在目标路径删除在源路径已经不存在的数据，可以使用选项`--delete`让 rsync 在同步数据时，自动删除目标路径中源路径上已经删除的数据

rsync 命令常常搭配 cron 定时任务，达到定期备份数据的效果

### fsarchiver 命令

fsarchiver 命令可以用来备份文件系统或分区，和 tar 不同，fsarchiver 会保留文件的扩展属性。

`fsarchiver savefs backup.fsa FS_OR_PARTITION1 FS_OR_PARTITION2 ...`备份文件系统或分区到指定文件

`fsarchiver restfs backup.fsa id=0,dest=DESTINATION1 id=1,dest=DESTINATION2`通过选项`id`指定提取备份文件中的某个分区，并恢复到指定位置

## 网络相关命令

### ssh 命令

SSH 代表 Secure Shell(安全 shell)，它使用加密隧道连接两台计算机，ssh 命令可以从本地连接到远程计算机上的 shell，从而在远程执行交互命令并接收结果或者启用交互会话等。

要使用 ssh，需要用包管理器安装 openssh-server 和 openssh-client，SSH 服务默认运行在端口 22 上。

`ssh username@remote_host`连接远程主机，也可以使用选项`-p`从指定端口进行连接

`ssh username@remote_host "command1;command2;..."`可以在远程主机上执行命令并且在本地 shell 中接收结果

`ssh -C username@remote_host`开启对数据进行压缩传输

可以通过 ssh 将数据从定向到远程的 stdin，例如：

`echo "test" | ssh username@remote_host 'echo'`将本地 stdin 的数据传递到远程主机的 stdin，

或者

`ssh username@remote_host 'echo' < file`将本地文件上的数据传递到远程主机的 stdin

### scp 命令

scp(Secure Copy Program)命令可以利用 ssh 加密通道进行文件的安全复制

`scp SOURCE DESTINATION`进行文件复制，其中的 SOURCE 和 DESTINATION 均可以采用形如`username@remote_host:/path`的形式指定远程位置

scp 使用 ssh 建立的加密隧道复制文件，因此使用和 ssh 服务一样的端口，即默认 22 端口，也可以通过选项`-oPort`指定其他端口

`scp -r SOURCE_FOLDER DESTINATION_FOLDER`可以递归的复制目录

`scp -p SOURCE DESTINATION`可以在复制时保留文件权限和属性

## 系统监视相关命令

### du 和 df 命令

du(disk usage)和 df(disk free)可以报告磁盘使用情况

`du file1 file2 ...`找出指定文件磁盘占用

`du -a dir1 dir2 ...`递归的输出指定目录中所有文件的磁盘使用情况

`du -h file`使用更友好可读的方式显示结果

`du -c dir`可以计算出文件或目录所占用的总的磁盘空间，同时也会输出单个文件的大小

使用选项`-b`、`-k`、`-m`可以强制使用特定单位显示磁盘使用情况

选项`--exclude`和`--exclude-from`可以从磁盘使用情况统计中排除指定文件或目录

du 命令提供的是磁盘使用情况，而 df 命令则提供磁盘可用空间信息，选项`-h`以易读的格式输出磁盘空间信息，客气 df 命令可以使用目录作为选项，在这种情况下，会输出该目录所在分区的可用磁盘分区信息，因此在不知道目录所在分区时，这种方法很有用。

### time 命令

time 命令可以测量出应用程序的执行时间：

`time APPLICATION`会执行应用，当应用执行完成后，将执行结果输出到 stdout，将执行应用所花费的 real 时间、sys 时间和 user 时间输出到 stderr，使用选项`-o`可以将时间信息写入到指定文件中

> time 命令的可执行二进制文件位于/usr/bin/time，另外还有一个 bash shell 的内建命令也叫做 time。当执行 time 时，默认调用的是 shell 的内建命令，该命令支持的选项有限，想要使用额外的功能，则需要明确调用/usr/bin/time

使用选项`-ao`可以将时间信息追加到原文件末尾

选项`-f`可以指定输出哪些统计信息以及其格式：

- C% 被计时的命令名称以及命令行参数
- D%进程非共享数据区的平均大小，单位 KB
- %E 进程使用的 real 时间
- %U user 时间
- x% 命令的退出状态
- k% 进程接受到的信号数量
- W% 进程被交换出主存的次数
- P% 进程所获得的 CPU 时间百分比，其值等于 user+sys 时间除以总运行时间
- K% 进程的平均中内存使用量，单位 KB
- W% 进程主动进入上下文切换的次数，例如等待 I/O 操作完成
- c% 进程被迫进入上下文切换的次数
- %S sys 时间
- %Z 系统分页大小
- %M 当前命令所使用的最大内存(KB 为单位)

#### Real 时间

Real 时间：指的是 Wall Clock Time(壁钟时间)，即命令从开始执行到结束的时间，包含执行命令期间被其他进程所占用的时间片(time slice)，以及进车被阻塞所消耗的时间(例如为等待 I/O 操作完成所用的时间)

#### User 时间

User 时间：指的是进程花费在用户模式(内核模式之外)中的 CPU 时间，这是执行进程所花费的时间，期间执行其他进程以及花费在阻塞状态中的时间并不计算在内

#### Sys 时间

Sys 时间：指的是进程花费在内核模式中的 CPU 时间，代表了在内核中执行系统调用所花费的时间

### 收集登录用户、启动日志及启动故障的相关信息

#### who 命令

获取当前登录用户的相关信息

#### w 命令

获取关于登录用户的详细信息

#### users 命令

只列出当前的登录用户列表

#### uptime 命令

显示系统的家电运行时长

#### last 命令

获取自文件`/var/log/wtmp`创建之后登录过系统的用户列表，跟上参数`USER`可以只显示具体用户的信息

#### lastb 命令

类似 last 命令，但是获取的是失败的用户登录会话信息

选项`-F`可以输出完整的时间信息

### watch 命令

watch 命令会按照指定的时间间隔来执行命令并显示其输出

`watch -n INTERVAL_TIME COMMAND`

使用选项`-d`可以着重标记出连续命令输出中的差异数据

### fsck 命令

`fsck PARTITION`检查指定分区或文件系统的错误

`fsck -A`检查/etc/fstab 中列出的所有文件系统

`fsck -a PARTITION`尝试自动修复指定分区或文件系统的错误

## 系统管理相关命令

### ps 命令

`ps`显示活跃进程的相关信息，默认只显示从当前终端所启动的进程

`ps -f`可以显示多列信息

选项`-e`和`-ax`可以输出系统中运行的所有进程信息

选项`-o PARAMETER1,PARAMETER2`可以指定显示哪些数据，选项`-o`的参数以逗号(,)作为参数分隔符，逗号与接下来的参数中间是没有空格的

选项`-o`支持的参数有：

- pcpu cpu 占用率
- pid 进程 id
- ppid 父进程 id
- pmem 内存使用率
- comm 可执行文件名
- cmd 简单命令
- user 启动进程的用户
- nice 优先级
- time 累计的 CPU 时间
- etime 进程启动后运行的时长
- tty 所关联的 TTY 设备
- euid 有效用户 id
- state 进程状态

选项`-u`指定有效用户列表

选项`-U`指定真实用户列表

### which 命令

`which COMMANDS`找出指定命令的位置

### whereis 命令

whereis 与 which 命令类似，它不仅返回命令的路径，还能打印出其对应的命令路径以及源代码路径

### whatis 命令

`whatis COMMANDS`输出指定命令的一行简短描述

### file 命令

`file FILENAME`可以用来确定文件的内容

### kill 命令

kill 可以中断正在运行的程序

`kill -l`列出所有可用的信号

`kill PROCESS_ID_LIST`发送 SIGTERM 信号终止进程，其中进程 id 列表使用空格作为分隔符

`kill -s SIGNAL PID`指定发送给进程的信号，常用的信号有以下几个：

- SIGHUP(1) 对控制进程或终端的结束进行挂起检测(hangup detection)
- SIGINT(2) 当按下 Ctrl-C 时发送此信号，终端进程
- SIGKILL(9) 强行杀死进程
- SIGTSTP(20) 当按下 Ctrl-Z 时发送此信号，将进程转入后台执行

> 注意当返送 SIGKILL 信号时，会立即生效，强行杀死进程，根本没有机会保存数据或执行通常的清理工作，因此因该优先使用 SIGTERM，将 SIGKILL 留作‘最后一招’

### killall 命令

kill 命令使用进程 ID 作为参数，而 killall 则可以直接使用进程名字

`killall PROCESS_NAME`，默认发送 SIGTERM 信号，也可以通过选项`-s`指定要发送的信号

`killall -9 PROCESS_NAME`可以强行杀死进程

`killall -u USERNAME PROCESS_NAME`指定进程所属用户

`killall -I PROCESS_NAME`在杀死进程前进行确认

### uname 命令

`uname -n`输出当前主机名，也可以使用`hostname`

`uname -a`输出 Linux 内核版本、硬件架构等详细信息

`uname -r`输出内核发行版本

`uname -m`输出主机类型

### cron 命令

cron 命令可以按照固定的时间间隔在后台自动执行指定任务，cron 命令使用一张表(crontab)来记录要执行的脚本或命令以及时间间隔

crontab 中每一行由 6 个字段构成，字段之间以空格分隔并按以下顺序排列：

1. 分钟 0~59
2. 小时 0~23
3. 天 1~31
4. 月 1~12
5. 星期中的某天 0~6
6. 在指定时间执行的脚本或命令

以上各个字段之间用空格分隔，单个字段内多个值由逗号分隔，字段中使用\*表示任何时间段，使用/表示每隔多少时间

`crontab -e`可以使用默认文本编辑器打开并编辑 cron 表

`crontab -l`可以查看当前用户的 cron 表

`crontab -l -u USERNAME`可以查看指定用户的 cron 表

`crontab -d`删除当前用户的 cron 表

`crontab -u USERNAME -d`删除指定用户的 cron 表

### convert 命令

convert 命令来自图像处理工具包 ImageMagick，该软件包需要使用包管理器下载安装

`convert INPUT_FILE OUTPUT_FILE`可以转换图像格式

`convert INPUT_FILE -resize WIDTHxHEIGHT OUTPUT_FILE`可以指定输出图像的宽高，如果只指定了宽高中的一项，则 convert 命令会按照原图比例自动计算另一项的值，如果使用的不是宽高数值而是百分数，则按指定百分比缩放图像

### 图像管理脚本

```sh img_helper.sh
#!/bin/bash
# 文件名：img_helper.sh
# 用途：图像管理
if [ $# -ne 4 -a $# -ne 6 -a $# -ne 8 ]
then
  echo Incorrect number of arguments
  exit 2
fi

while [ $# -ne 0 ]
do

  case $1 in
  -source) shift;source_dir=$1;shift;;
  -scale) shift;scale=$1;shift;;
  -percent) shift;percent=$1;shift;;
  -dest) shift;dest_dir=$1;mkdir -p $dest_dir;shift;;
  -ext) shift;ext=$1;shift;;
  *) echo Wrong parameters;exit 2;;
  esac

done

for img in `ls $source_dir | egrep '*.(jpg|png)'`
do
  source_file=$img
  if [[ -n $ext ]]
  then
    dest_file=${img%.*}.$ext
  else
    dest_file=$img
  fi

  if [[ -n $dest_dir ]]
  then
    dest_file=${dest_file##*/}
    dest_file="$dest_dir/$dest_file"
  fi

  if [[ -n $scale ]]
  then
    PARAM="-resize $scale"
  elif [[ -n $percent ]]
  then
    PARAM="-resize $percent%"
  fi

  echo Processing file: $source_file
  convert $source_file $PARAM $dest_file

done
```

该脚本接受以下参数：

- -source：指定图像源目录
- -dest：指定转换后文件的目录，如果没有指定该选项，则和源目录相同
- -ext：指定转换后文件格式
- -percent：指定图像缩放比例(不能和选项-scale 同时出现)
- -scale：指定图像缩放宽高(不能和选项-percent 同时出现)
