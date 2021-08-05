---
title: JS中this指向类型总结
date: 2021-08-06 02:05:14
tags:
  - JavaScript
categories:
  - 前端开发
---

## 概述

&emsp;&emsp;在 JS 中，this 是在函数被调用时确定的，它的指向**完全却决于函数调用的地方，而不是它被声明的地方(箭头函数除外)**。当一个函数被调用时，会创建一个执行上下文，其中记录了函数在哪里被调用(调用栈)、函数的调用方式、传入的参数等信息，this 就是这个记录的一个属性，会在函数执行过程中被用到。

this 的指向分为以下几种场景：

1. 作为构造函数被 new 调用
2. 作为对象的方法被调用
3. 作为函数直接调用
4. 被 call、apply、bind 调用
5. 箭头函数中的 this

<!-- more -->

## new 绑定，指向实例对象

&emsp;&emsp;当函数作为构造函数使用 new 调用时，this 绑定的是新创建的构造函数的实例：

```javascript
function Foo() {
  console.log(this);
}

const bar = new Foo(); // 输出Foo的实例，this就是bar
```

## 隐式绑定，指向上下文对象

&emsp;&emsp;当函数作为对象的方法调用时，this 绑定到该上下文对象：

```javascript
const a = "hello";

const obj = {
  a: "world",
  foo: function () {
    console.log(this.a);
  },
};

obj.foo(); // 输出world
```

&emsp;&emsp;如果嵌套了多个对象，那么 this 指向的是最后一个调用该方法的上下文对象：

```javascript
var a = "hello";

var obj = {
  a: "world",
  b: {
    a: "China",
    foo: function () {
      console.log(this.a);
    },
  },
};

obj.b.foo(); // 输出 China
```

## 默认绑定，非严格模式下绑定到全局对象，严格模式下为 undefined

&emsp;&emsp;当函数被独立调用时，在非严格模式下，this 绑定到全局对象(浏览器下是 window，node 环境下是 global)，严格模式下，this 绑定到 undefined(因为严格模式不允许 this 指向全局对象)：

```javascript
var a = "hello";

function foo() {
  var a = "world";
  console.log(this.a);
  console.log(this);
}

foo(); // 输出 hello, 浏览器中输出window对象，node环境下输出global对象
```

&emsp;&emsp;有时会遇到类似下面这种情况：

```javascript
var a = "hello";

var obj = {
  a: "world",
  foo: function () {
    console.log(this.a);
  },
};

var bar = obj.foo;

bar(); // 输出 hello
```

&emsp;&emsp;这时，虽然 bar 的值是 obj 对象的方法 foo，但是 bar 函数是独立调用的，因此属于默认绑定的情况，this 指向全局对象，这种情况和把方法作为回调函数的场景类似：

```javascript
var a = "hello";

var obj = {
  a: "world",
  foo: function () {
    console.log(this.a);
  },
};

function func(fn) {
  fn();
}

func(obj.foo); // 输出 hello
```

&emsp;&emsp;参数传递实际上是一种隐式赋值，这里将 obj.foo 方法隐式赋值给函数 func 的形参 fn，这类场景常见的有 setTimeout 和 setInterval，如果回调函数不是箭头函数，其中的 this 就指向全局对象。其实可以把默认绑定当作是隐式绑定的特殊情况，即把函数作为全局对象的方法进行调用，因此其中的 this 隐式绑定到全局对象。

## 显示绑定，绑定到指定对象

&emsp;&emsp;可以通过 call、apply、bind 修改函数绑定的 this，使其成为我们指定的对象，这些方法的第一个参数将显式的绑定 this：

```javascript
var obj = {
  a: 1,
  b: 1,
  foo: function (x) {
    console.log(this.a + this.b + x);
  },
};

obj.foo(1); // 输出 3
obj.foo.call({ a: 2, b: 2 }, 1); // 输出 5
obj.foo.apply({ a: 2, b: 2 }, [1]); // 输出 5

var bar = obj.foo.bind({ a: 2, b: 2 }, 1);

bar(); // 输出 5
```

&emsp;&emsp;call 和 apply 的区别是，call 方法接受参数列表，apply 方法接受参数数组，而 bind 方法则将第一个参数与 this 绑定，之后的参数作为原函数的参数序列的前若干项，返回一个新函数。

## 箭头函数中的 this

&emsp;&emsp;箭头函数中的 this 根据其声明的地方来决定 this 的指向，是当前所在词法作用域中的绑定，通常是箭头函数所在的函数作用域。箭头函数的 this 无法通过 call、apply、bind 进行修改，而且因为箭头函数没有构造函数 constructor，所以也不可以被 new 调用，即不能作为构造函数使用。

## 小结

&emsp;&emsp;this 存在多种使用场景，如果多个场景同时出现，this 会根据优先级来确定指向：**_new 绑定 > 显式绑定 > 隐式绑定 > 默认绑定_**。

&emsp;&emsp;因此，当我们要判断 this 的指向时，可以采用以下判断顺序和方法：

1. new 绑定：函数是否由 new 调用？如果是则 this 绑定到新创建的对象实例
2. 显式绑定：函数是否通过 call、apply、bind 调用？如果是则 this 绑定到指定的对象
3. 隐式绑定：函数是否在某个上下文对象中调用？如果是则 this 绑定到这个上下文对象
4. 默认绑定：如果以上都不是，在严格模式下 this 绑定为 undefined，在非严格模式下 this 绑定到当前环境的全局对象
