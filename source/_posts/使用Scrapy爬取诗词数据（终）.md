---
title: 使用Scrapy爬取诗词数据（终）
date: 2021-05-04 16:27:07
tags:
  - Python
  - Scrapy
categories:
  - 网络爬虫
---

前文中，我们已经成功从诗词详情页爬取到了数据，接下来对数据内容根据需求进行加工处理以及存储。

首先，对标题进行处理，将其改为原标题加上正文第一句的形式。对数据的处理可以通过自定义管道来实现，scrapy 的管道可以将数据一层一层的进行复杂逻辑的处理，每一个管道类都需要返回 item，已保证数据可以在多个管道类之间流动。

使用 scrapy 创建爬虫项目时，会在项目目录下自动创建一个`pipelines.py`文件，其中已经预定义了一个和项目同名的管道类，我们就从这里开始编写数据处理逻辑：

```python
import logging

from itemadapter import ItemAdapter
from scrapy.exception import DropItem

from .processors import modify_title

class ZhscCrawlerPipeline:
    def __init__(self):
        self.logger=logging.getLogger(__name__)

    def process_item(self,item,spider):
        adapter = ItemAdapter(item)
        if adapter['title'] is None or adapter['content'] is None:
            raise DropItem()
        adapter['title'] = modify_title(adapter['title'], adapter['content'])
        self.logger.debug(u'标题已成功经过修改，格式为：原标题 —— 诗文内容第一行 -- %(title)s', {'title': adapter['title']})
        spider.crawler.stats.inc_value('title_modify/modified', spider=spider)
        return item
```

<!-- more -->

这里引入了`ItemAdapter`，这是 scrapy 提供的用于处理 item 的类，可以通过字段名获取 item 中的数据。

首先提取`title`字段和`content`字段的值，并且如果标题为空或者正文为空时，抛出一个`DropItem`，这是 scrapy 提供的用于丢弃数据的类，此处诗词数据如果没有标题或正文，则将该条数据抛弃。

然后调用在`processors.py`中自定义的标题处理方法`modify_title`，将处理后的返回值赋值给`title`字段以覆盖原标题，最后使用 python 的标准库`logging`打印日志，方便调试。

`spider.crawler.stats.inc_value`是 scrapy 内置的状态记录方法，同样用于调试时查看爬虫运行情况。

下面是`modify_title`的代码：

```python
def modify_title(title, content):
    first_line = re.match(r'(.+)(?=\n)', content).group()
    title = title+' —— '+first_line
    return title
```

处理逻辑很简单，使用正则提取正文第一句，由于在 item 中定义`content`字段时，使用了`parse_content`方法把正文的每一个完整诗句进行换行，所以我们只需要匹配第一个换行符前面的内容就可以得到正文第一句。处理后返回的结果为：“原标题 —— 正文第一句”。

到此，可以运行爬虫爬取符合需求的诗词数据了，接下来对数据进行存储。最简单的存储方式就是在`settings.py`爬虫配置文件中，配置`FEEDS`字段，scrapy 默认支持的存储方式主要有：Local filesystem、FTP、S3、Google Cloud Storage 和 Standard output，这里我们配置为使用 JSON Lines 格式将数据存储到项目根目录下的`poems`目录下，文件名为`poems.jsonl`，该格式类似 JSON，使用逐行的方式存储数据，每行都是一个标准的 JSON 字符串，其优点一是方便追加数据，二是每一行都是一个标准的 JSON 格式字符串，所以使用的时候可以按行读取数据，避免文件过大，一次全部读取造成性能瓶颈。

```python
FEEDS={
    pathlib.Path('poems/poems.jsonl'):{
        'format':'jsonlines',
        'encoding':'utf-8'
    }
}
```

相比于直接存储与本地文件，更好的方式是使用数据库进行存储，下面在`pipelines.py`中编写一个`MongoDBPipeline`来通过自定义管道将数据存储进 MongoDB 中，在 python 中使用 mongodb 推荐使用 pymongo。

```python
class MongoDBPipeline:
    def __init__(self, host='127.0.0.1', port=27017,username='',password='',auth_source='', db_name='zhsc_crawler', col_name='poems'):
        self.host=host
        self.port=port
        self.username=username
        self.password=password
        self.auth_source=auth_source
        self.db_name=db_name
        self.col_name=col_name
        self.logger=logging.getLogger(__name__)

    @classmethod
    def from_crawler(cls,crawler):
        _host = crawler.settings.get('MONGO_HOST', '127.0.0.1')
        _port = crawler.settings.getint('MONGO_PORT', 27017)
        _username=crawler.settings.get('MONGO_USERNAME','root')
        _password=crawler.settings.get('MONGO_PASSWORD','123456')
        _auth_source=crawler.settings.get('MONGO_AUTHSOURCE','admin')
        _db_name = crawler.settings.get('MONGO_DB', 'zhsc_crawler')
        _col_name = crawler.settings.get('MONGO_COLLECTION', 'poems')
        return cls(_host, _port,_username,_password,_auth_source, _db_name, _col_name)
```

上面代码首先读取 mongodb 配置，准备好进行数据库连接，其中类方法`from_crawler`是 scrapy 提供的管道类中读取爬虫配置文件的方法。

在`settings.py`中配置 mongodb：

```python
MONGO_HOST = "127.0.0.1"
MONGO_PORT = 27017
MONGO_USERNAME = 'root'
MONGO_PASSWORD = '123456'
MONGO_AUTHSOURCE = 'admin'
MONGO_DB = "zhsc_crawler"
MONGO_COLLECTION = "poems"
```

MongoDB 的相关知识这里不单独做解释，网上资料很多，而且 MongoDB 上手也很简单。这里配置使用的数据库名称为`zhsc_crawler`，集合名称`poems`。

对数据库的连接和关闭可以放在运行爬虫和爬虫运行完毕时，这样可以有效节省开销：

```python
def open_spider(self,spider):
    self.connection = pymongo.MongoClient(host=self.host, port=self.port,username=self.username,password=self.password,authSource=self.auth_source)
    self.db = self.connection[self.db_name]
    self.collection = self.db[self.col_name]

def close_spider(self,spider):
    self.connection.close()
```

`open_spider`和`close_spider`由 scrapy 提供，用于在蜘蛛启动和关闭时自定义操作。

最后是管道类必须实现的方法`process_item`，用于处理数据：

```python
def process_item(self,item,spider):
    adapter = ItemAdapter(item)
    self.collection.insert_one(dict(item))
    self.logger.debug(u'数据已插入MongoDB！ %(title)s -- %(times)s -- %(author)s',{'title': adapter['title'], 'times': adapter['times'], 'author': adapter['author']})
    spider.crawler.stats.inc_value('mongodb/inserted', spider=spider)
    return item
```

最后，在`settings.py`中配置`ITEM_PIPELINES`字段，开启自定义管道，默认只开启了创建项目时 scrapy 自动创建的项目同名管道类：

```python
ITEM_PIPELINES={
    'zhsc_crawler.pipelines.ZhscCrawlerPipeline':300,
    'zhsc_crawler.pipelines.MongoDBPipeline':500
}
```

其中的数值表示优先级，数值越小优先级越高，数据会依从优先级顺序在管道中传递进行处理。

到这里，爬虫开发已经接近完成，下面来考虑一些优化设置。

首先，一些大型网站，或者迭代周期很长的网站，他们的页面中可能存在着一些循环引用的链接，可能是无意造成的，也可能是故意设置，使爬虫陷入死循环，已进行反爬。因此我们因该在爬取时对重复的请求链接进行过滤。scrapy 默认开启了 RFPDupeFilter，通过生成一个 request_seen 文件记录请求指纹，然后在每次发出请求前先检查当前请求是否已经记录过，从而达到过滤重复请求的目的。

然后，当我们爬取的数据量非常大时，request_seen 文件体积将会不断增大，而运行爬虫时需要将该文件读入内存，这可能造成内存占用过大，最终导致程序崩溃。

一种办法是改成使用 Redis 来存储请求指纹，借助 Redis 的高性能，不需要一次性读取全部记录，从而改善默认 RFPDupeFilter 的缺陷，但是数据量太大时，使用 Redis 存储请求指纹仍然会占用大量内存。

这里采用另一种方式，Redis 结合布隆过滤器进行过滤。布隆过滤器的详细原理可以自行上网了解，布隆过滤器的优点是占用空间很少，缺点则是有一定的误判率，使用 Redis 内置的 bitset 可以方便的实现布隆过滤器，下面直接给出代码以及简单解释，在项目目录下新建`dupefilter.py`：

```python
import hashlib
import logging

from redis import Redis
from scrapy.dupefilters import BaseDupeFilter
from scrapy.utils.request import request_fingerprint

from .hashmap import HashMap
```

这里引入 scrapy 提供的 `BaseDupeFilter` 作为自定义 dupefilter 的基类，以及 `request_fingerprint` 方法生成请求指纹。

引入 python 标准库 `hashlib` 用于后面使用 md5 和 logging 生成日志。

自定义类`HashMap`用于生成布隆过滤器使用的哈希函数。

引入 redis 来连接操作 Redis。

```python
class HashMap():
    def __init__(self,m,seed):
        self.m=m
        self.seed=seed

    def hash(self,value):
        ret=0
        for i in range(len(value)):
            ret+=self.seed*ret+ord(value[i])
        return (self.m-1)&ret
```

上面代码中，m 为布隆过滤器需要使用的位大小，seed 用于生成多个 hash 函数，hash 方法则把输入字符串映射到多个位，并且将对应位设置为 1。

下面编写基于 Redis 的布隆过滤器的主体代码：

```python
class RedisBloomDupeFilter(BaseDupeFilter):
    def __init__(self, host='localhost', port=6379, db=0, bitSize=32, seeds=[5, 7, 11], blockNum=1, key='bloomfilter'):
        self.redis = Redis(host=host, port=port, db=db)  # 连接Redis
        self.bitSize = 1 << bitSize  # 在Redis中申请一个BitSet，Redis中BitSet实际上使用String进行存储，因此最大容量为512M，即2^32
        self.seeds = seeds  # 生成多个hash函数的种子
        self.key = key  # Redis中使用的键名
        self.blockNum = blockNum  # Redis中总共申请多少个BitSet
        self.hashFunc = []  # hash函数
        for seed in self.seeds:
            # 根据提供的种子生成多个hash函数
            self.hashFunc.append(HashMap(self.bitSize, seed))
            self.logger = logging.getLogger(__name__)

    @classmethod
    def from_settings(cls,settings):
        # scrapy提供的dupefilter中读取爬虫配置的方法
        _host = settings.get('REDIS_HOST', 'localhost')
        _port = settings.getint('REDIS_PORT', 6379)
        _db = settings.getint('REDIS_DUPE_DB', 0)
        _bitSize = settings.getint('BLOOMFILTER_BIT_SIZE', 32)
        _seeds = settings.getlist('BLOOMFILTER_HASH_SEEDS', [])
        _blockNum = settings.getint('BLOOMFILTER_BLOCK_NUMBER', 1)
        _key = settings.get('BLOOMFILTER_REDIS_KEY', 'bloomfilter')
        return cls(_host, _port, _db, _bitSize, _seeds, _blockNum, _key)
```

在`settings.py`中加入 Redis 和布隆过滤器相应配置：

```python
REDIS_HOST = "127.0.0.1"
REDIS_PORT = 6379
REDIS_DUPE_DB = 0
BLOOMFILTER_REDIS_KEY = "bloomfilter"
BLOOMFILTER_BLOCK_NUMBER = 1
BLOOMFILTER_BIT_SIZE = 31
BLOOMFILTER_HASH_SEEDS = [5, 7, 11, 13, 31, 37]
```

接着完成`dupefilter.py`：

```python
    def request_seen(self, request):
        fp = request_fingerprint(request)
        if self.exists(fp):
            # 如果请求指纹已经存在
            return True
        self.insert(fp)  # 如果请求指纹不存在
        return False

    def insert(self, str_input):
        """
        加入请求指纹
        """
        md5 = hashlib.md5()
        md5.update(str(str_input).encode('utf-8'))
        _input = md5.hexdigest()
        _name = self.key+str(int(_input[0:2], 16) % self.blockNum)
        for func in self.hashFunc:
            """
            将hash映射后的bit为置位为1
            """
            _offset = func.hash(_input)
            self.redis.setbit(_name, _offset, 1)

    def exists(self, str_input):
    """
    判断请求指纹是否已存在
    """
    if not str_input:
        return False
    md5 = hashlib.md5()
    md5.update(str(str_input).encode('utf-8'))
    _input = md5.hexdigest()
    _name = self.key+str(int(_input[0:2], 16) % self.blockNum)
    ret = True
    for func in self.hashFunc:
        """
        如果经过hash映射之后对应的bit位上有任意一个0，则一定不存在
        """
        _offset = func.hash(_input)
        ret = ret & self.redis.getbit(_name, _offset)
    return ret

    def log(self, request, spider):
    self.logger.debug(u'已过滤的重复请求：%(request)s', {'request': request})
    spider.crawler.stats.inc_value('redisbloomfilter/filtered', spider=spider)
```

最后，在`settings.py`中开启自定义 dupefilter：

```python
DUPEFILTER_CLASS = 'zhsc_crawler.dupefilter.RedisBloomDupeFilter'
```

最后，在做一些反爬优化，首先可以通过为每个请求添加随机 User-Agent 来伪装不同客户端，要实现这一点可以通过scrapy的`Downloader Middleware`，下载器中间件位于downloader和scrapy engine之间，当engine通知downloader开始从指定url下载数据前，可以在下载器中间件中定义一些预操作。例如，先在`settings.py`中添加一组 UA，可以从网上找到很多 UA 信息，然后自定义一个`ZhscRandomUserAgentMiddleware`中间件类，每当downloader开始下载数据前，都对请求头设置一个随机UA：

```python
class ZhscRandomUserAgentMiddleware:
    def __init__(self, user_agents=[]):
        self.user_agents = user_agents

    @classmethod
    def from_crawler(cls, crawler):
        return cls(crawler.settings.getlist('UA_Pool'))

    def process_request(self, request, spider):
        if self.user_agents is not None and len(self.user_agents) > 0:
            request.headers.setdefault(b'User-Agent', random.choice(self.user_agents))
```

其中，`from_crawler`是 scrapy 提供的读取配置文件的类方法，而`process_request`则是中间件类必须实现的请求处理方法。

```python
UA_Pool = [
    # User-Agent
    'User-Agent, Mozilla/5.0 (Windows NT 10.0;Win64;x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.114 Safari/537.36 Edg/89.0.774.76',
    'User-Agent,Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50',
    'User-Agent,Mozilla/5.0 (Windows; U; Windows NT 6.1; en-us) AppleWebKit/534.50 (KHTML, like Gecko) Version/5.1 Safari/534.50',
    'User-Agent,Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0;',
    'User-Agent,Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0; Trident/4.0)',
    'User-Agent,Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.0)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'User-Agent, Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv,2.0.1) Gecko/20100101 Firefox/4.0.1',
    'User-Agent,Mozilla/5.0 (Windows NT 6.1; rv,2.0.1) Gecko/20100101 Firefox/4.0.1',
    'User-Agent,Opera/9.80 (Macintosh; Intel Mac OS X 10.6.8; U; en) Presto/2.8.131 Version/11.11',
    'User-Agent,Opera/9.80 (Windows NT 6.1; U; en) Presto/2.8.131 Version/11.11',
    'User-Agent, Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.11 (KHTML, like Gecko) Chrome/17.0.963.56 Safari/535.11',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Maxthon 2.0)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; TencentTraveler 4.0)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; The World)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Trident/4.0; SE 2.X MetaSr 1.0; SE 2.X MetaSr 1.0; .NET CLR 2.0.50727; SE 2.X MetaSr 1.0)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; 360SE)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; Avant Browser)',
    'User-Agent, Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)',
    'User-Agent,Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 UBrowser/6.2.4094.1 Safari/537.36']
```

然后在`settings.py`中配置使用自定义中间件：

```python
# Enable or disable downloader middlewares
# See https://docs.scrapy.org/en/latest/topics/downloader-middleware.html
DOWNLOADER_MIDDLEWARES = {
    #    'zhsc_crawler.middlewares.ZhscCrawlerDownloaderMiddleware': 543,
    # 发出请求前添加随机UA
    'scrapy.downloadermiddlewares.useragent.UserAgentMiddleware': None,
    'zhsc_crawler.middlewares.ZhscRandomUserAgentMiddleware': 800
}
```

这里注意要先关闭 scrapy 默认的 UA 中间件。

最后，如果爬虫频繁发出大量请求的话，很容易被做了反爬的网站发现，因此可以通过在`settings.py`中对爬虫进行限速来预防，scrapy 提供了很方便的实现方式：

```python
# Enable and configure the AutoThrottle extension (disabled by default)
# See https://docs.scrapy.org/en/latest/topics/autothrottle.html
AUTOTHROTTLE_ENABLED = True
# The initial download delay
AUTOTHROTTLE_START_DELAY = 5
# The maximum download delay to be set in case of high latencies
AUTOTHROTTLE_MAX_DELAY = 60
# The average number of requests Scrapy should be sending in parallel to
# each remote server
AUTOTHROTTLE_TARGET_CONCURRENCY = 1.0
# Enable showing throttling stats for every response received:
AUTOTHROTTLE_DEBUG = False
```

到此，整个诗词数据爬虫开发便完成了，完整代码放在我的[github 仓库](https://github.com/Christopher-Teng/poems_crawler.git)。
