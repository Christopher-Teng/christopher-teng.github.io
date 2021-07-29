---
title: 使用Flask实现简单的用户注册登录功能
date: 2021-07-21 16:26:26
tags:
  - Python
  - Flask
categories:
  - Web开发
---

&emsp;&emsp;Flask 是 Python 世界中非常流行的 Web 框架之一，其以轻量和上手简单著称，被称作微框架(microframework)，它可以很好的结合 MVC 模式，通过丰富的插件库根据自身需求进行定制化，在短时间内就能完成一个功能丰富的中小型 Web 服务开发。

&emsp;&emsp;本文中我们将尝试使用 Flask 来实现简单的用户注册登录功能，涉及到构建蓝图、使用 jinja2 模板引擎渲染前端页面、使用 SQLAlchemy 操作 MySQL 数据库、使用 WTForms 验证用户提交的表单信息、使用 Cookie 保存用户登录状态、设置路由守卫对页面进行访问控制，最后使用自定义函数装饰器和 Python 标准库中的 contextmanager 上下文管理器，优化数据库操作，增加设置默认查询条件功能和操作失败自动回滚功能。通过这样一个简单的项目，能够对使用 Flask 进行 Web 开发的流程有一个初步的认识，并且熟悉一些开发中常用的 Flask 第三方插件，提升代码质量、加快开发速度，避免重复造轮子。

## 搭建项目结构

&emsp;&emsp;如下图所示：

{% asset_img skeleton.jpeg "project skeleton" %}

&emsp;&emsp;根目录下的 app.py 作为入口文件启动项目，app 是整个项目的开发目录，app/config 是配置文件目录、app/forms 是表单校验文件目录、app/lib 是自定义工具类文件目录、app/manager 是路由蓝图文件目录、app/models 是数据库文件目录、app/static 是静态文件目录、app/templates 是模板文件目录。

&emsp;&emsp;项目根目录下的 Pipfile 和 Pipefile.lock 是使用 pipenv 构建虚拟开发环境产生的配置文件。

## 启动服务

&emsp;&emsp;要使用 Flask 启动一个 Web 服务非常简单：创建一个 Flask 实例，传入自定义配置或者直接使用默认配置，定义一个路由绑定视图函数，调用实例的 run 方法。

&emsp;&emsp;首先在 app/**init**.py 中创建实例并进行配置：

```python app/__init__.py
from flask import Flask

def create_app():
    app=Flask(__name__)
    app.config.from_pyfile("config/setting.py")
    return app
```

&emsp;&emsp;然后在项目入口文件 app.py 中导入 Flask 实例并启动服务：

```python app.py
from app import create_app

app=create_app()

@app.route("/")
def index():
    return "<h1>Hello World!</h1>"


if __name__=="__main":
app.run(host="0.0.0.0")
```

&emsp;&emsp;这里调用 run 方法时传入参数`host="0.0.0.0"`是为了可以在开发时通过局域网内的设备进行访问。

&emsp;&emsp;对于配置文件来说，到目前只需要配置开启 debug 模式，方便开发中发生错误时查看详细异常信息。

```python app/config/setting.py
DEBUG=True
```

&emsp;&emsp;最后，运行入口文件启动服务：

> $ python ./app.py

&emsp;&emsp;浏览器访问 localhost:5000 就可以看到项目首页。

<!-- more -->

## 路由和蓝图

&emsp;&emsp;蓝图(blueprint)是一个模块化处理的类，它将单个应用的视图、模板和静态文件进行结合，可以看作是一个存储和操作路由映射方法的容器，主要用来实现客户端请求和 URL 相互关联的功能。

&emsp;&emsp;下面我们将之前注册的首页路由以蓝图的方式来实现。

&emsp;&emsp;在项目根目录下的 manager 目录用于统一存放蓝图文件，首先创建一个名为 web 的蓝图：

```python app/manager/blueprint.py
from flask import Blueprint

web=Blueprint("web",__name__,url_prefix="/")
```

&emsp;&emsp;然后使用新创建的蓝图来注册首页路由：

```python app/manager/web.py
from .blueprint import web

@web.route("/")
def index():
  return "<h1>Hello World!</h1>"
```

&emsp;&emsp;在 app/manager/**init**.py 中引入该目录下的 web.py，这样之后导入 app/manager 时会自动应用 web.py 中注册的路由：

```python app/manager/__init__.py
from . import web
```

&emsp;&emsp;最后，在应用中注册新创建的蓝图：

```python app/__init__.py
from flask import Flask

def register_blueprint(app):
  from .manager.blueprint import web
  app.register_blueprint(web)


def create_app():
  app=Flask(__name__)
  app.config.from_pyfile("config/setting.py")
  register_blueprint(app)
  return app
```

## 连接数据库

&emsp;&emsp;在 Python 世界中，连接关系型数据库常用 SQLAlchemy，其秉持 Code First 的思想，以 ORM(对象关系映射)的方式操作数据库，大大降低了开发难度。在 Flask 的插件库中同样有对应的插件 Flask-SQLAlchemy，该插件对原生的 SQLAlchemy 进行了封装，方便和 Flask 结合使用。

### 初步实现

&emsp;&emsp;首先对数据库进行配置：

```python app/config/setting.py
DEBUG=True
SECRET_KEY="!@#$%^&*"
SQLALCHEMY_DATABASE_URI="mysql+pymysql://root:123456@localhost:3306/flask"
SQLALCHEMY_ECHO=True
SQLALCHEMY_TRACK_MODIFICATION=True
```

&emsp;&emsp;配置项都比较简单易懂，具体说明可以自行网上查看。

&emsp;&emsp;接下来进行数据表的定义，在 app/models 目录中统一存放数据库操作相关文件，首先创建一个基类，用于定义后面将要实现的用户表中的用户注册时间字段以及激活/冻结状态字段。

```python app/models/base.py
from datetime import datetime

from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import Column,Integer,SmallInteger

db=SQLAlchemy()

class Base(db.Model):
  __abstract__=True
  status=Column(SmallInteger,default=1)
  create_time=Column("create_time",Integer,nullable=False)

  def __init__(self):
    self.create_time=int(datetime.now().timestamp())
```

&emsp;&emsp;这里在 Base 类中设置`__abstract__=True`是因为这只是定义一个基类，不需要在数据库中对应生成一个表，如果不设置`__abstract__=True`，则 SQLAlchemy 会因为 Base 类中没有指定主键而报错。

&emsp;&emsp;接下来实现用户表：

```python app/models/user.py
from sqlalchemy import Column,Integer,String

from .base import Base

class User(Base):
  id=Column(Integer,primary_key=True)
  nickname=Column(String(20),nullable=False)
  email=Column(String(50),nullable=False,unique=True)
  phone_number=Column("phone_number",String(11),nullable=False,unique=True)
  password=Column(String(32),nullable=False)
```

&emsp;&emsp;最后，在应用中初始化 ORM 模型并且创建数据表：

```python app/__init__.py
from flask import Flask

def register_blueprint(app):
  from .manager.blueprint import web
  app.register_blueprint(web)


def create_db(app):
  from .models.base import db
  db.init_app(app)
  db.create_all(app=app)


def create_app():
  app=Flask(__name__)
  app.config.from_pyfile("config/setting.py")
  register_blueprint(app)
  create_db(app)
  return app
```

### 对用户密码进行加密

&emsp;&emsp;让我们在回过头看看用户表的定义，其中有几个问题，首先，用户密码任何时候都不能以明文存储，这一点可以利用 Flask 使用的 WSGI 工具包——werkzeug 来解决：

```python app/models/user.py
from sqlalchemy import Column,Integer,String
from werkzeug.security import check_password_hash,generate_password_hash

from .base import Base

class User(Base):
  id=Column(Integer,primary_key=True)
  nickname=Column(String(20),nullable=False)
  email=Column(String(50),nullable=False,unique=True)
  phone_number=Column("phone_number",String(11),nullable=False,unique=True)
  _password=Column("password",String(128),nullable=False)

  @property
  def password(self):
    return self._password


  @password.setter
  def password(self,raw):
    self._password=generate_password_hash(raw)


  def check_password(self,raw):
    return check_password_hash(self.password,raw)
```

### 设置默认查表条件

&emsp;&emsp;在实际应用中，用户注册或删除一般采用软删除的方式，及设置标志位，这里我们在 Base 类中使用`status`来表示，默认值 1 表示用户为激活状态，设为 0 则表示用户被冻结。因此，当我们查询用户表时，始终都应该指定`status=1`为查询条件，如果总是在执行查询命令时手动指定，无疑使代码非常冗余，因此我们需要实现一个指定默认查询条件的功能。

&emsp;&emsp;在 app/lib 目录下创建一些自定义工具类：

```python app/lib/helper.py
from functools import wraps

def set_query_conditions(**conditions):
  def decorator(func):
    @wraps(func)
    def wrapper(*args,**kwargs):
      for k,v in conditions.items():
        if k not in kwargs.keys():
          kwargs[k]=v
      return func(*args,**kwargs)
    return wrapper
  return decorator
```

&emsp;&emsp;`set_query_conditions`是一个自定义函数装饰器，接下来对 app/models/base 中 Base 类所继承的 db.Model 进行改在，利用我们的自定义函数装饰器为数据库查询方法`filter_by`指定默认条件：

```python app/models/base.py
from datetime import datetime

from flask_sqlalchemy import BaseQuery,SQLAlchemy
from sqlalchemy import Column,Integer,SmallInteger

from ..lib.helper import set_query_conditions

class CustomQuery(BaseQuery):
  @set_query_conditions(status=1)
  def filter_by(self,**kwargs):
    return super().filter_by(**kwargs)

db=SQLAlchemy(query_class=CustomQuery)

class Base(db.Model):
  __abstract__=True
  status=Column(SmallInteger,default=1)
  create_time=Column("create_time",Integer,nullable=False)

  def __init__(self):
    self.create_time=int(datetime.now().timestamp())
```

### 操作失败自动回滚

&emsp;&emsp;最后，我们还可以对数据库操作进一步优化，添加上自动回滚功能，这里可以通过 Python 标准库 contextlib 中的 contextmanager 来实现，其原理是使用了上下文管理器，在进入和离开上下文环境时，执行指定的操作，具体细节可以上网查看：

```python app/models/base.py
from contextlib import contextmanager
from datetime import datetime

from flask_sqlalchemy import BaseQuery,SQLAlchemy
from sqlalchemy import Column,Integer,SmallInteger

from ..lib.helper import set_query_conditions

class CustomQuery(BaseQuery):
  @set_query_conditions(status=1)
  def filter_by(self,**kwargs):
    return super().filter_by(**kwargs)

db=SQLAlchemy(query_class=CustomQuery)

class Base(db.Model):
  __abstract__=True
  status=Column(SmallInteger,default=1)
  create_time=Column("create_time",Integer,nullable=False)

  def __init__(self):
    self.create_time=int(datetime.now().timestamp())


  @classmethod
  @contextmanager
  def auto_commit(cls):
    try:
      yield
      db.session.commit()
    except Exception as e:
      db.session.rollback()
      raise e
```

## 校验表单数据

&emsp;&emsp;Flask 内部并没有提供全面的表单验证功能，所以需要借助一些第三方插件来实现，这里采用了 WTForms。WTForms 是一个支持多种 Web 框架的 Form 插件，主要用于对用户请求数据进行校验，而 Flask 插件库中也有对应版本——Flask-WTForms。

&emsp;&emsp;在 app/forms 目录下新建 auth.py 用来统一编写表单校验类：

```python app/forms/auth.py
from flask_wtf import FlaskForm
from wtforms import PasswordField,StringField,ValidationError
from wtforms.fields.html5 import EmailField
from wtforms.validators import DataRequired,Length,Email,Regexp

from ..models.user import User
```

&emsp;&emsp;注意，这里用到的邮箱验证器可能需要单独安装 email-validator 包，可以自行视情况进行安装。

&emsp;&emsp;接上文，在 app/forms/auth.py 中定义表单验证类，其中除了使用 WTForms 提供的标准验证器外，还使用了自定义验证器，方式是以 `validate_[字段名称](self,field)`为名定义实例方法，WTForms 会将其自动应用到对应的字段上，而验证失败则需要抛出 WTForms 的 ValidationError 类的实例：

```python app/forms/auth.py
# 接上文
class UserForm(FlaskForm):
    nickname = StringField(validators=[DataRequired(),
                                       Length(min=4, max=20),
                                       Regexp(r"^\w{4,20}$", flags=0, message=u"用户昵称最少4位最多20位字符，并且不能使用特殊字符！")])
    email = EmailField(validators=[DataRequired(),
                                   Length(min=6, max=50)])
    phone_number = StringField(validators=[DataRequired(),
                                           Length(min=11, max=11),
                                           Regexp(r"^(13[0-9]|14[01456879]|15[0-35-9]|16[2567]|17[0-8]|18[0-9]|19[0-35-9])\d{8}$", flags=0, message=u"无效的手机号码")])
    password = PasswordField(validators=[DataRequired(),
                                         Length(min=6, max=32),
                                         Regexp(r"^\w{6,32}$", flags=0, message=u"密码最少6位最多32位字符，并且不能使用特殊字符")])

    def validate_email(self, field):
        if User.query.filter_by(email=field.data).first():
            raise ValidationError(u"该邮箱已被注册！")

    def validate_phone_number(self, field):
        if User.query.filter_by(phone_number=field.data):
            raise ValidationError(u"该手机号码已被注册！")
```

## 用户注册接口与页面

### 路由和视图函数

&emsp;&emsp;首先新建一个蓝图管理与用户操作相关的路由：

```python app/manager/blueprint.py
from flask import Blueprint

web=Blueprint("web",__name__,url_prefix="/")
auth=Blueprint("auth",__name__,url_prefix="/user")
```

&emsp;&emsp;新建一个文件统一管理用户路由相关的视图函数：

```python app/manager/auth.py
from flask import flash,redirect,render_template,url_for,request

from ..forms.auth import UserForm
from ..models.base import db
from ..models.user import User
from .blueprint import auth

@auth.route("/register",methods=["GET","POST"])
def register():
  form=UserForm()
  if form.validate_on_submit():
    pass
  return "<h1>Register Page</h1>"
```

&emsp;&emsp;这里通过 flask-wtforms 提供的 validate_on_submit 方法，在得到客户端通过 POST 请求提交表单内容并且通过表单数据校验后，做进一步处理，而通过 GET 请求访问路由时则返回 html。这里暂时先返回一个页面标题，后面会使用 jinja2 模板引擎渲染 html 页面进行返回。

&emsp;&emsp;接下来完成用户注册逻辑：

```python app/manager/auth.py
# 接上文if语句块
# if form.validate_on_submit():
  nickname=form.data.get("nickname")
  email=form.data.get("email")
  phone_number=form.data.get("phone_number")
  password=form.data.get("password")
```

&emsp;&emsp;首先通过前面定义的 UserForm 类的实例来获得用户提交的表单数据，这里所获得的数据都是通过 wtforms 校验后的正确数据，而校验失败的信息会被放入 form.errors 中，后面会在通过模板引擎渲染 html 页面时通过条件判断，在页面中显示校验失败的错误信息。

&emsp;&emsp;下面新建一条用户记录并写入数据库：

```python app/manager/auth.py
# 接上文
  user=User()
```

&emsp;&emsp;这里实例化一个 user 后需要添加用户属性，因此在 Base 类中增加一个添加用户属性的方法：

```python app/models/base.py
# 在Base类中添加add_attrs方法
  def add_attrs(self,**attrs):
    for k,v in attrs.items():
      if hasattr(self,k) and k!="id":  # 不能指定主键
        setattr(self,k,v)
```

&emsp;&emsp;回到用户注册视图函数中继续编写：

```python app/manager/auth.py
# 接上文
  user.add_attrs(nickname=nickname,
                 email=email,
                 phone_number=phone_number,
                 password=password)
  try:
    with User.auto_commit():
      db.session.add(user)
    return redirect(url_for("auth.login"))
  except Exception as _:
    flash(u"注册失败！")
```

&emsp;&emsp;当成功注册以后，跳转到登录试图，否侧提示注册失败，这里所使用的 flash 是 Flask 提供的消息闪现方法，可以在渲染 html 页面时取得该方法传递的信息在页面中进行展示，后面在使用模板引擎编写 html 页面时会用到。

&emsp;&emsp;注意这里在想数据库写入数据时，通过 with...as 语句调用了前面自定义的方法：auto_commit(由于该方法并没有返回值，所以省略了 as 关键字)，该方法通过 python 的上下文管理器来实现数据库操作失败自动回滚，并抛出错误。

&emsp;&emsp;下面在应用中注册蓝图，引入路由：

```python app/manager/__init__.py
from . import auth,web
```

```python app/__init__.py
# register_blueprint函数定义内
# def register_blueprint(app):
  from .manager.blueprint import auth,web
  app.register_blueprint(auth)
  app.register_blueprint(web)
```

### 模板引擎与注册页面

&emsp;&emsp;下面使用 jinja2 模板引擎编写 html 页面。所有模板文件统一放置与 app/templates 目录下进行管理，这也是 Flask 默认的模板文件查找目录。jinja2 支持变量、条件、循环、继承等特性，具体使用方法可以上网查看。

&emsp;&emsp;首先创建一个基础模板统一页面布局：

```html app/templates/layout.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="stylesheet" href="../static/bootstrap-icons.css" />
    <link rel="stylesheet" href="../static/bootstrap.min.css" />
    <title>Flask Learn</title>
  </head>
  <body class="bg-dark text-light">
    {% block header %} Here is the header area! {% endblock %} {% block aside %}
    Here is the aside area! {% endblock %} {% block main %} Here is the main
    area! {% endblock %} {% block footer %} Here is the footer area! {%
    endblock%}
    <script src="../static/bootstrap.bundle.min.js"></script>
  </body>
</html>
```

&emsp;&emsp;然后编写头部导航、侧栏提示信息以及页脚：

```html app/templates/base.html
{% extends "layout.html" %} {% block header %}
<header class="container-fluid header">
  <nav class="navbar navbar-expand-sm navbar-dark bg-dark">
    <a class="navbar-brand" href="javascript:;">Flask Learn</a>
    <button
      class="navbar-toggler"
      type="button"
      data-bs-toggle="collapse"
      data-bs-target="#navbarNav"
      aria-controls="navbarNav"
      aria-expanded="false"
      aria-label="Toggle navigation"
    >
      <span class="navbar-toggler-icon"></span>
    </button>
    <div
      class="collapse navbar-collapse justify-content-between"
      id="navbarNav"
    >
      <ul class="navbar-nav">
        <li class="nav-item">
          <a class="nav-link {{'active' if active=='index'}}" href="/"
            >Home <i class="bi bi-house-fill"></i
          ></a>
        </li>
        <li class="nav-item">
          <a
            class="nav-link {{'active' if active=='customer'}}"
            href="/customer"
            >Customers <i class="bi bi-person-fill"></i
          ></a>
        </li>
      </ul>
      <div class="text-end">
        {% if current_user and current_user.nickname %}
        <a href="/customer" class="btn btn-primary"
          >{{ current_user.nickname }} <i class="bi bi-person-square"></i
        ></a>
        <a href="/user/logout" class="btn btn-outline-primary"
          >Logout <i class="bi bi-box-arrow-left"></i
        ></a>
        {% else %}
        <a
          href="/user/login"
          class="btn {{ 'btn-primary' if active=='login' else 'btn-outline-primary' }}"
          >Login <i class="bi bi-box-arrow-in-right"></i
        ></a>
        <a
          href="/user/register"
          class="btn {{ 'btn-outline-primary' if active=='login' else 'btn-primary' }}"
          >Sign up <i class="bio bi-people-fill"></i
        ></a>
        {% endif %}
      </div>
    </div>
  </nav>
</header>
{% endblock %} {% block main %} {% endblock %}{% block aside %}
<aside class="aside container">
  {% with messages=get_flashed_messages() %} {% for message in messages %}
  <div>
    {% if message %}
    <p class="alert alert-warning fs-6 text-break" role="alert">{{message}}</p>
    {% endif %}
  </div>
  {% endfor %} {% endwith %} {% if form and form.errors %}
  <div>
    {% for _,v in form.errors.items() %} {% for msg in v %} {% if msg %}
    <p class="alert alert-warning fs-6 text-break" role="alert">{{msg}}</p>
    {% endif %} {% endfor %} {% endfor %}
  </div>
  {% endif %}
</aside>
{% endblock %} {% block footer %}
<footer class="footer w-100 py-3 text-center text-secondary fs-6">
  &copy;Christopher-Teng
</footer>
{% endblock %}
```

&emsp;&emsp;样式上面直接使用了 Bootstrap，相关静态文件放置与 app/static 下面：

{% asset_img static_dir.jpeg "static files" %}

&emsp;&emsp;其中，侧边栏中`{% with messages=get_flashed_messages() %}`使用了 Flask 提供的闪现(flash)在页面中嵌入视图函数中传入的自定义信息，`{% if form and form.errors %}`则是表单信息通过 wtforms 验证失败后的错误信息，通过在视图函数中使用`render_template`渲染模板时，传入 form 表单验证对象取得。

&emsp;&emsp;下面编写用户注册页面：

```html app/templates/register.html
{% extends "base.html" %} {% set active="register" %} {% block main %}
<main class="main row my-3 text-secondary">
  <form action="/user/register" method="POST" class="col-sm-6 mx-auto px-3">
    <div class="form-floating mb-2">
      <input
        type="text"
        class="form-control"
        id="nicknameInput"
        placeholder="your nickname"
        name="nickname"
        required
        value="{{form.data.get('nickname')|default('',True)}}"
      />
      <label for="nicknameInput">Nickname</label>
    </div>
    <div class="form-floating mb-2">
      <input
        type="email"
        class="form-control"
        id="emailInput"
        placeholder="your email"
        name="email"
        required
        value="{{form.data.get('email')|default('',True)}}"
      />
      <label for="emailInput">Email address</label>
    </div>
    <div class="form-floating mb-2">
      <input
        type="text"
        class="form-control"
        id="phoneNumberInput"
        placeholder="your phone number"
        name="phone_number"
        required
        value="{{form.data.get('phone_number')|default('',True)}}"
      />
      <label for="phoneNumberInput">Phone number</label>
    </div>
    <div class="form-floating mb-2">
      <input
        type="password"
        class="form-control"
        id="passwordInput"
        placeholder="password"
        name="password"
        required
      />
      <label for="passwordInput">Password</label>
    </div>
    <input type="hidden" name="csrf_token" value="{{csrf_token()}}" />
    <button class="w-100 btn btn-primary btn-lg" type="submit">Sign up</button>
  </form>
</main>
{% endblock %}
```

&emsp;&emsp;上面注册表单中，`<input type="hidden" name="csrf_token" value="{{csrf_token()}}" />`使用了表单隐藏字段，用于防御 CSRF(跨站请求伪造，Cross-site request forgery)，这是 flask-wtf 插件提供的功能，需要使用 flask-wtf 的 CsrfProtect 类的实例来初始化应用：

```python app/__init__.py
# 接上文
from flask_wtf import CsrfProtect

# def create_app():
  # app=Flask(__name__)
  csrf=CsrfProtect()
  csrf.init_app(app)
  # pass
```

&emsp;&emsp;到此，用户注册功能已经实现，下面实现用户登录功能。

## 用户登录接口与页面

&emsp;&emsp;用户登录的代码和用户注册非常相似，主要区别是在表单数据上，登录页面可以使用注册过的邮箱或者手机号来进行用户验证，因此在视图函数中应该对表单数据做邮箱和手机号两方面验证，具体代码如下：

```python app/manager/auth.py
# 接上文
  @auth.route("/login",methods=["GET","POST])
  def login():
    form=LoginForm()
    if form.validate_on_submit():
      email_or_phone_number=request.form.get("email_or_phone_number")
      password=request.form.get("password)
      user=_login(email_or_phone_number)
      if user and user.check_password(password):
        return redirect(url_for("web.index"))
      flash(u"用户不存在或密码错误！")
    return render_template("login.html",form=form)

  def _login(email_or_phone_number):
    user=User.query.filter_by(email=email_or_phone_number).first() or User.query.filter_by(
      phone_number=email_or_phone_number).first()
    return user
```

&emsp;&emsp;编写登录页表单验证：

```python app/forms/auth.py
# 接上文
class LoginForm(FlaskForm):
    email_or_phone_number = StringField(validators=[DataRequired()])
    password = PasswordField(validators=[DataRequired(),
                                         Length(min=6, max=32),
                                         Regexp(r"^\w{6,32}$", flags=0, message=u"密码最少6位最多32位字符，并且不能使用特殊字符")])

    def validate_email_or_phone_number(self, field):
        res = re.search(
            r"^((\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*)|((13[0-9]|14[01456879]|15[0-35-9]|16[2567]|17[0-8]|18[0-9]|19[0-35-9])\d{8}))$",
            field.data)
        if not res:
            raise ValidationError("please input email or phone number!")
```

&emsp;&emsp;以及登录页面：

```html app/templates/login.html
{% extends "base.html" %} {% set active="login" %} {% block main %}
<main class="main row my-3 text-secondary">
  <form
    action="{{url_for('auth.login',next=request.args.get('next'))}}"
    method="POST"
    class="col-sm-6 mx-auto px-3"
  >
    <div class="form-floating mb-2">
      <input
        type="text"
        class="form-control"
        id="emailOrPhoneNumberInput"
        placeholder="email or phone number"
        name="email_or_phone_number"
        required
      />
      <label for="emailOrPhoneNumberInput">Email / Phone number</label>
    </div>
    <div class="form-floating mb-2">
      <input
        type="password"
        class="form-control"
        id="passwordInput"
        placeholder="password"
        name="password"
        required
      />
      <label for="passwordInput">Password</label>
    </div>
    <div class="form-check mb-2 py-2 d-flex justify-content-center">
      <input
        type="checkbox"
        class="form-check-input"
        id="rememberMeCheck"
        name="remember_me"
        value="remember_me"
      />
      <label for="rememberMeCheck" class="form-check-label ms-2"
        >Remember me</label
      >
    </div>
    <input type="hidden" name="csrf_token" value="{{csrf_token()}}" />
    <button class="w-100 btn btn-primary btn-lg" type="submit">Login</button>
  </form>
</main>
{% endblock %}
```

## 用户登录状态保持

&emsp;&emsp;当用户登录以后，往往需要保持用户登录状态，一方面提高用户体验，不需要每次打开页面都要求重新登录，另一方面，在多个页面之间共享登录状态，实现访问控制和一些特殊的业务逻辑。

&emsp;&emsp;下面将使用 Flask 的第三方插件 flask-login 来实现登录状态保持，首先实例化一个 flask-login 插件的 LoginManager 类，然后初始化应用：

```python app/__init__.py
# 接上文
from flask_login import LoginManager

login_manager=LoginManager()

# def create_app():
  # app=Flask(__name__)
  login_manager.init_app(app)
  # pass
```

&emsp;&emsp;flask-login 提供了很多可配置项，下面首先配置 login_view——未登录时自动跳转的 endpoint 和提示信息：

```python app/__init__.py
# 接上文
  # login_manager.init_app(app)
  login_manager.login_view="auth.login"
  login_manager.login_message="Please login first"
  # pass
```

&emsp;&emsp;改写用户信息表的代码，加入 flask-login，具体用法可以网上查找文档自行了解：

```python app/models/user.py
class User(Base, UserMixin):
    id = Column(Integer, primary_key=True)
    nickname = Column(String(20), nullable=False)
    email = Column(String(50), nullable=False, unique=True)
    phone_number = Column("phone_number", String(11), nullable=False, unique=True)
    _password = Column("password", String(128), nullable=False)

    @property
    def password(self):
        return self._password

    @password.setter
    def password(self, raw):
        self._password = generate_password_hash(raw)

    def check_password(self, raw):
        return check_password_hash(self.password, raw)


@login_manager.user_loader
def load_user(uid):
    return User.query.filter_by(id=uid).first()
```

&emsp;&emsp;UserMixin 是 flask-login 提供的方便开发者进行扩展的基类，主要提供了一些使用 flask-login 所必须要实现的类方法。

&emsp;&emsp;flask-login 默认只在会话期间记录用户登录状态，但是可以通过指定 remember 的相关配置，在指定时间内保持登录状态。

&emsp;&emsp;首先在配置文件中对 flask-login 进行配置：

```python app/__init__.py
from datetime import timedelta

DEBUG = True
SECRET_KEY = "!@#$%^&*"
SQLALCHEMY_DATABASE_URI = "mysql+pymysql://root:123456@localhost:3306/flask"
SQLALCHEMY_ECHO = True
SQLALCHEMY_TRACK_MODIFICATION = True
REMEMBER_COOKIE_DURATION = timedelta(days=7)
REMEMBER_COOKIE_HTTPONLY = True
```

&emsp;&emsp;这里配置为保存用户登录信息 7 天。接下来在用户登录视图函数中记录登录状态：

```python app/manager/auth.py
# 接上文
# def login():
#   pass
#   if user and user.check_password(password):
      login_user(user, remember=remember_me)
            next = request.args.get("next")
            print("next: {}".format(next))
            next = next if next and next.startswith("/") else "/"
            return redirect(next)
#   pass
```

&emsp;&emsp;其中，next 是当我们访问要求登录验证的页面时，flask-login 会将请求重定向到我们设置的`login_view`，而跳转前的 path 则会被已查询参数的方式记录下来，及 next 的值，因此当用户成功登录后，可以通过 next 参数将页面重定向到用户之前试图访问的页面，这里要注意对 next 进行必要的验证，防止通过访问登陆页面时指定恶意的 next 查询参数进行攻击。

&emsp;&emsp;最后，加上用户登出逻辑，并且添加一个用户页面进行访问控制：

```python app/manager/auth.py
# 接上文
@auth.route("/logout")
@login_required
def logout():
    logout_user()
    return redirect(url_for("web.index"))
```

```python app/manager/web.py
# 接上文
from flask_login import login_required

@web.route("/customer")
@login_required
def customer():
    return render_template("customer.html")
```

```html app/templates/customer.html
{% extends "base.html" %} {% set active="customer" %} {% block main %}
<main class="main">
  <h1 class="h1 text-center">
    Welcome back,{{current_user.nickname | default("",true)}}!
  </h1>
</main>
{% endblock %}
```

## 总结

&emsp;&emsp;在本篇中，通过实现一个非常简单经典的用户注册、登录功能，熟悉了 flask 的基础开发流程，了解了 flask 中的消息闪现、jinja 模板以及 blueprint 蓝图，另外还涉及到了一些常用的 flask 第三方插件，主要有 flask-sqlalchemy 使用 ORM 数据模型进行数据库操作、flask-wtf 进行表单校验以及 flask-login 进行登录状态保持，并且通过自定义函数装饰器和上下文管理器对数据库操作进行了优化，实践了这两种 python 中的高级语法。文中项目完整代码参见[此处](https://github.com/Christopher-Teng/flask_signup-login-logout)。
