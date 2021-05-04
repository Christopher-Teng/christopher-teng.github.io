---
title: 使用Scrapy爬取诗词数据（续）
date: 2021-05-03 19:08:49
tags:
  - Python
  - Scrapy
categories:
  - 网络爬虫
---

在上一篇文章中，我们已经完成了对目标网站的分析([中华诗词网](https://www.zhsc.net))，接下来开始进行爬虫开发。

首先启动一个新项目，搭建基本目录结构，这里推荐使用 virtualenv 创建 python 虚拟环境进行开发。

```shell
mkdir poems_crawler && cd $_

virtualenv -p Python3 venv

. venv/bin/activate
```

以上命令创建了一个 poems_crawler 空目录，并进入目录启激活 python3 虚拟环境。

接下来安装 scrapy 并创建一个 zhsc_crawler 的项目：

```shell
pip install scrapy3

scrapy startproject zhsc_crawler
```

到这里，我们使用 scrapy 新建了一个 zhsc_crawler 项目，在当前目录下多出了一个名为 zhsc_crawler 的项目根目录，进入项目目录：

```shell
cd zhsc_crawler
```

查看目录结构可以看到在项目根目录下还有一个同名的目录`zhsc_crawler`，以及一个名为 scrapy.cfg 的 scrapy 配置文件。这里的`zhsc_crawler`目录就是爬虫项目的包目录，这里也是之后我们自己编写代码的地方，其下包含了 items.py(Item 定义文件)、middlewares.py(自定义中间件)、pipelines.py(自定义管道)、settings.py(项目配置文件)和一个名为`spiders`的目录，这是放置爬虫类的包目录。

<!-- more -->

现在来创建我们的蜘蛛类：

```shell
scrapy genspider poems www.zhsc.net
```

现在在`spiders`目录下会生成一个 poems.py 文件，我们在这里来编写蜘蛛。

首先修改其中的`start_urls`，也就是爬虫开始发起请求的地址，根据前面的分析，种子页应该是作者列表页：

```python
start_urls=['https://www.zhsc.net/Index/shi_more.html']
```

现在来编写处理种子页响应的代码，在`poems.py`中，对`start_urls`发起的请求，其响应会被`parse`方法处理，因此先来看看在`parse`方法里面怎么写：

```python
author=getattr(self,'author',None)
```

前面说过，爬虫将被设计为爬取指定作者的诗词数据，在 scrapy 中提供了通过 scrapy cli 向蜘蛛中动态传入参数的功能，其方式为：

```shell
scrapy crawl poems -a author=李白
```

通过`-a`选项传入的参数会被传递给蜘蛛类的`__init__`方法成为蜘蛛实例上的一个属性，因此通过 getattr 方法便可以获取由命令行传入的参数。

下一步，对作者列表进行筛选，匹配指定的作者。

首先因该从页面中提取所有作者的链接，在 scrapy 中可以使用 xpath 和 css 两种方式来获取 html 内容：

```python
author_links=response.css('.ci_lei1>.ci_lei1>.ci_lei1_xuan>.ci_lei1_xuan2 a').getall()
```

`response.css`是使用 scrapy 的 css 选择器获取 html 内容，得到的结果可以通过`get`和`getall`方法来取得第一项匹配结果或所有匹配结果的列表。这里使用`getall`得到当前页面包含的所有作者链接。

接下来从所有作者中匹配指定的作者：

```python
if author is not None:
  for link in author_links:
    poems_list_page_url=find_author_url(link,author)
    if poems_list_page_url is not None:
      yield response.follow(poems_list_page_url,self.parse_list)
return ZhscCrawlerItem()
```

这里我们使用`for...in`遍历作者列表来进行匹配，这里引入的自定义的方法`find_author_url`，如果调用该方法成功返回了链接地址，则使用 scrapy 提供的`response.follow`方法让蜘蛛沿着指定的链接继续爬取，最后`return ZhscCrawlerItem()`是返回爬取到的数据，这是新建爬虫项目时，scrapy 自动为我们在`items.py`中生成的数据类，稍后我们会在这里对爬取数据进行定义。

先来看看自定义的`find_author_url`方法，其定义在项目目录下的`processors.py`中：

```python
def find_author_url(link,author):
  if re.search(r'>\s*{}\s*<'.format(author),link) is not None:
    return re.search(r'(?:href\s*\=\s*")(.+?)(?:")',link).group(1)
  return None
```

逻辑很简单，使用正则先匹配指定作者，如果找到则返回其链接，否则返回`None`。

现在如果我们传入作者名字并且假定这是一个被收录在目标网站中的作者，那么蜘蛛将会进入诗词列表页面，下面来看看怎么编写处理诗词列表页面的方法`parse_list`：

```python
detail_urls=response.css('.zh_sou_jie>.zh_jie_con a::attr(href)').getall()
```

scrapy 的 css 选择器使用`::attr`的语法来提取 html 标签中的属性，这里首先提取当前诗词列表页面中的所有诗词详情页地址。然后让蜘蛛跟随详情页链接，进入下一步详情页爬取：

```python
for url in detail_urls:
  yield response.follow(url,self.parse_item)
```

之前分析过，诗词详情由于条目众多，目标网站使用了分页器，因此在诗词列表页的处理中还因该让蜘蛛跟随分页器的链接继续爬取：

```python
next_page_urls=response.css('.page a::attr(href)').getall()
for url in next_page_urls:
  yield response.follow(url,self.parse_list)
```

到这一步，蜘蛛应该可以顺利到达所有的诗词详情页，接下来编写蜘蛛的核心代码，对数据页的爬取：

```python
def parse_item(self,response):
  loader=ItemLoader(item=ZhscCrawlerItem(),response=response)
```

这里使用了两个新类`ItemLoader`和`ZhscCrawlerItem`，上面提到过，`ZhscCrawlerItem`是新建爬虫时 scrapy 自动为我们创建的数据类，而`ItemLoader`则是 scrapy 为我们提供的数据处理类，可以直接引入：

```python
from scrapy.loader import ItemLoader
```

首先来定义数据类，根据前文分析，要爬取的数据主要包含标题 title、年代 times、作者 author 和正文 content，在项目目录下的`items.py`中定义数据结构：

```python
from itemloaders.processors import Join,MapCompose,TakeFirst
from scrapy.item import Field,Item

from .processors import get_author,get_times,parse_content

class ZhscCrawlerItem(Item):
  title=Field(input_processor=MapCompose(str.strip,stop_on_none=True),output_processor=TakeFirst())
  times=Field(input_processor=MapCompose(get_times,stop_on_none=True),output_processor=TakeFirst())
  author=Field(input_processor=MapCompose(get_author,stop_on_none=True),output_processor=TakeFirst())
  content=Field(input_processor=MapCompose(parse_content,stop_on_none=True),output_processor=Join(''))
```

scrapy 中定义数据结构使用`Item`和`Field`基类，使用语法`字段名=Field()`来规定数据因该包含的字段。

前文中已经分析过，对详情页中原始的标题、年代、作者和正文数据因该先进行处理，让我们回顾一下：

1. 标题要修改为原始标题加上正文内容的第一句
2. 年代和作者信息位于同一个`<p>`标签内，要分别进行提取
3. 正文结构不尽相同，有些诗词正文中还带有注释内容，需要进行过滤

scrapy 中允许我们对从页面中获取的数据进行处理之后，再往后传递给 Downloader Middleware，即下载器中间件，负责将爬取的数据按配置进行存储。

在`Field`中，使用`input_processor`和`output_processor`在获取数据后和输出数据前进行自定义处理，而`itemloaders.processors`中提供了`Join`、`MapCompose`和`TakeFirst`三个数据处理方法，其中`Join`和`TakeFirst`用于`output_processor`，顾名思义，这两个方法分别用于将数据列表中的每一项合并后输出，和获取数据列表中的第一项输出。

`MapCompose`方法用于`input_processor`，可以传入多个方法，`MapCompose`会将获取的数据依次传递给这些方法处理，然后将结果交给向后传递。由于获取的原始数据可能是一个列表，比如上面的诗词正文，在详情页中，正文是位于一个`<div>`标签下的多个文本节点组成的，因此通过 scrapy 的 css 选择器得到的是一个列表，假如列表中某一项为空值，而我们指定的处理方法可能无法处理输入值为空的情况，这是便会报错，所以可以在`MapCompose`中指定`stop_on_none=True`来规定遇到空值时停止继续处理。

`get_author`、`get_times`和`parse_content`是`processors.py`中的三个自定义的处理函数：

```python
def get_author(value):
  result=re.search(r'(?:作者:\s*)(.*)(?:\s*)',value)
  return result.group(1)

def get_times(value):
  result=re.search(r'(?:年代:\s*)(.+?)(?:\s)',value)
  return result.group(1)

def parse_content(value):
  value=remove_tags(value.strip())
  return re.sub(r'(。|！|？)',r'\1\n',value)
```

这里使用了 python 标准库`w3lib`里面的 remove_tags 方法去除 html 标签：

```python
from w3lib.html import remove_tags
```

`re.sub(r'(。|！|？)',r'\1\n',value)`在句号或感叹号或问号后面添加一个换行，这是为了符合阅读诗词时的习惯：在一个完整的诗句后面换行。

在这里并没有对标题进行处理(将标题修改为原始标题加上正文第一句)，因为在这里主要是定义数据结构，使用`input_processor`和`output_processor`的目的是正确提取数据，规范数据内容，而对标题的处理属于项目设计的需求，因此将放到后面自定义管道中再进行。

回到蜘蛛`poems.py`中，现在处理详情页的方法如下：

```python
def parse_item(self,response):
  loader=ItemLoader(item=ZhscCrawlerItem(),response=response)
```

接着往下，向`loader`中传入定义的字段数据：

```python
loader.add_css('title', '.zh_shi_xiang1>span::text,.zh_shi_xiang1>span>*::text')
loader.add_css('times', '.zh_shi_xiang1>p::text')
loader.add_css('author', '.zh_shi_xiang1>p::text')
loader.add_css('content', '.zh_shi_xiang1>div::text,.zh_shi_xiang1>div>*::text')
return loader.load_item()
```

`loader.add_css`方法使用 scrapy 的 css 选择器将 html 中的内容添加到在`ZhscCrawlerItem`中定义的指定字段，最后使用`loader.load_item`方法将获取的数据返回，这里要注意使用`add_css`方法后，只是 item 的指定字段注入数据，但是数据并不会被返回，所以在完成向所有字段注入数据后，一定要调用`load_item`方法将数据返回。
