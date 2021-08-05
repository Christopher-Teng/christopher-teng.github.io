---
title: JS中的闭包与高阶函数
date: 2021-08-06 03:18:43
tags:
  - JavaScript
categories:
  - 前端开发
---

## 概述

&emsp;&emsp;JS 中的函数是一等公民，可以和其他对象一样，有自己的属性和方法，可以赋值给一个变量，可以放进数组中作为元素，可以作为其他函数的参数,等等......普通对象能做的它能做，普通对象不能做的它也能做。因为 JS 中函数的这种特性，因而产生了很多特殊的情形，比如闭包和高阶函数。

<!-- more -->

## 闭包

&emsp;&emsp;当函数可以**记住并访问**所在词法作用域时，就产生了闭包，即使函数是在当前词法作用域之外执行：

```javascript
function foo() {
  var a = 2;

  function bar() {
    console.log(a);
  }

  return bar;
}

var baz = foo();

baz(); // 输出 2
```

&emsp;&emsp;一般来说，函数在执行完后其整个内部作用域都会被销毁，因为 JavaScript 的 GC(Garbage Collection)垃圾回收机制会自动回收不再使用的内存空间。但是闭包会阻止某些 GC，比如上面例子中的 foo()执行完成后，因为返回的 bar 函数依然持有其所在作用域的引用，所以其内部作用域不会被回收。如果不是必须使用闭包，因该尽量避免产生闭包，因为闭包在处理速度和内存消耗方面对性能具有负面影响。

&emsp;&emsp;闭包的一个典型应用是备忘模式(结果缓存)。当一个函数存在复杂的执行过程，造成大量开销的话，可以在函数内部用一个对象来存储每次执行的结果，当下次执行时，如果用到同样的数据，就可以直接从这个缓存对象中取出数据，节省执行开销：

```javascript
function memories(fn) {
  const _cache = {};
  return function (...rest) {
    const key = JSON.stringify(rest);
    return _cache[key] || (_cache[key] = fn.apply(fn, rest));
  };
}
```

&emsp;&emsp;这里的 JSON.stringify 把传给 memories 函数的参数序列化成字符串，把它当作\_cache 的索引，将 memories 函数的运行结果当作索引的值传递给\_cache，这样 memories 运行的时候，如果传递的参数之前传递过，那么就可以直接返回缓存好的结果，如果传递的参数没有使用过，则执行 memories 并将结果缓存。另外，还可以在实际使用时进行优化，一方面缓存不可以永远扩张下去，这样太耗费内存资源，可以设置只缓存最新传入的 n 个参数的结果，另一方面，可以借助浏览器的持久化手段进行缓存持久化，比如 cookie、localStorage 等。

## 高阶函数

&emsp;&emsp;高阶函数即函数的输入参数中有函数，或者返回结果是函数。函数作为参数的情况，常见的场景就是回调函数，比如 setTimeout、setInterval 等，函数作为返回值的情况，常见的场景就是闭包的使用，利用闭包的特性来保持作用域。

&emsp;&emsp;下面列举几个高阶函数的常用情况：

### 柯里化

&emsp;&emsp;柯里化(Currying)，又称部分求值(Partial Evaluation)，是把接受多个参数的原函数变换成接受一个单一参数(原函数的第一个参数)的函数，并且返回一个新函数，新函数能够接受余下的参数，最后返回同原函数一样的结果。柯里化的核心思想是把多参数传入的函数拆成单(或部分)参数函数，内部再返回调用下一个单(或部分)参数函数，依次处理剩余的参数。柯里化有 3 个常见作用：**参数复用**、**提前返回**、**延迟计算/运行**：

```javascript
function currying(fn, ...rest1) {
  return function (...rest2) {
    return fn.apply(fn, rest1.concat(rest2));
  };
}
```

### 反柯里化

&emsp;&emsp;柯里化是固定部分参数，返回一个接受剩余参数的函数，也称为部分计算函数，目的是为了缩小适用范围，创建一个针对性更强的函数。反柯里化的意义和用法正好和柯里化相反，是为了扩大适用范围，创建一个应用范围更广的函数，使本来只有特定对象才适用的方法，扩展到更多的对象：

```javascript
function unCurrying(fn) {
  return function (target, ...rest) {
    return fn.apply(target, rest);
  };
}
```

&emsp;&emsp;可以这样理解柯里化和反柯里化的区别：柯里化是在运算前提前传参，可以传递多个参数；反柯里化是延迟传参，在运算时把原来已经固定的参数或者 this 上下文等当作参数延迟到未来传递。

### 消抖函数

&emsp;&emsp;消抖函数(deBounce)可以在指定的间隔时间段内阻止原函数的重复执行，提高性能：

```javascript
function debounce(fn, delay = 200) {
  let timer = null;
  return function (...args) {
    timer && clearTimeout(timer);
    timer = setTimeout(() => {
      fn.apply(this, args);
    }, delay);
  };
}
```

### 偏函数

&emsp;&emsp;偏函数是创建一个调用另外一个部分(参数或变量已预制的函数)的函数，函数可以根据传入的参数来生成一个真正执行的函数。其本身不包括我们真正需要的代码，只是根据传入的参数返回其他函数，返回的函数中才有真正的处理逻辑：

```javascript
function isType(type) {
  return function (obj) {
    return Object.prototype.toString.call(obj) === `[object ${type}]`;
  };
}

var isString = isType("String");
var isNumber = isType("Number");
var isBoolean = isType("Boolean");
var isUndefined = isType("Undefined");
var isNull = isType("Null");
var isObject = isType("Object");
var isSymbol = isType("Symbol");
var isFunction = isType("Function");
```

&emsp;&emsp;这样就利用偏函数快速创建了一组判断对象类型的方法。

&emsp;&emsp;偏函数和柯里化的区别：柯里化是把一个接受 n 个参数的函数，有原本的一次性传递所有参数并执行变成了可以分多次接受参数再执行；偏函数固定了函数的某个部分，通过传入的参数或者方法返回一个新的函数来接受剩余的参数，数量可能是一个也可能是多个；当一个柯里化函数只接受两次参数时，这时的柯里化函数和偏函数概念类似，可以认为偏函数是柯里化函数的退化版。
