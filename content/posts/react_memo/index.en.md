---
weight: 1
title: "React - memo, useMemo, useCallback"
date: 2022-06-06T21:29:01+08:00
lastmod: 2022-06-06T21:29:01+08:00
draft: false
author: "Christine Li"
images: []
resources:
- name: "featured-image"
  src: "nightSnow.png"

tags: ["react", "frontend"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

What is memo, useMemo, useCallback? and When to use them?

<!--more-->

# React - memo, useMemo, useCallback

React 中当组件的 props 或 state 变化时，会重新渲染，实际开发会遇到不必要的渲染场景。比如： 父组件：

```JavaScript
import { useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);

  return (
    <div><button onClick={()=>setCount(count + 1)}>点击次数：{count}</button>
        <Child />
    </div>
  );
};
```

useState会在每次值更新的时候渲染，每次`count`变化时，父组件重新渲染，会导致<Child />也重新渲染， **那么如何让父组件的渲染不影响子组件呢？🧐**

# React.memo()

在上述情况下，可以使用React.memo()将子元素包住。`React.memo`用来缓存组件的渲染，避免不必要的更新。因为，React.memo 是对组件进行 “记忆”，**当它接收的 props 没有发生改变的时候，那么它将返回上次渲染的结果，不会重新执行函数返回新的渲染结果**。

```JavaScript
import { memo } from "react";

export const Child = memo(() => {
  console.log("渲染了");
  return <div>子组件</div>;
});
```

尤其在项目里，当依赖比较多的时候，会经常触发重新渲染组件，这时候可以将子组件都用memo()包住，减少不必要的重新渲染，之前遇到过一个例子，在渲染长列表时，由于没有使用memo()，每做一个操作整个列表都会闪一下，这种时候甚至会影响到直观效果展示。

> ❗️上面的例子中，父组件只是简单调用子组件，并未给子组件传递任何属性

那如果传入属性呢？

上面我们也说到，这种不变依赖于“props不变”， 但是当传入子组件的props变化的时候子组件就会重新渲染，**但如果传入的只是一个函数呢**？**这时候是没有必要让子组件渲染一遍的**。比如：

```JavaScript
import { useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);
  const [name, setName] = useState("小明");
  const increment = () => setCount(count + 1);

  const onClick = (name: string) => {
    setName(name);
  };

  return (
    <div>
        <button onClick={increment}>点击次数：{count}</button>
        <Child name={name} onClick={onClick} />
    </div>
  );
};
```

如果传递的是函数，子组件还是会重新渲染。

父组件向子组件传递函数，父组件重新渲染时，**会重新创建 onClick 函数**，即传给子组件的 onClick 属性发生了变化，导致子组件渲染

那么这时候如何解决呢？这时候就用到useCallBack！

# React.useCallback()

把回调函数及依赖项数组作为参数传入 `useCallback`，它将返回该回调函数的`memoized回调函数`，该回调函数**仅在某个依赖项改变时才会更新**。

> `memoized`回调函数: 使用一组参数初次调用函数时，缓存参数和计算结果，当再次使用相同的参数调用该函数时，直接返回相应的缓存结果。

可以将onClick用useCallBack包裹一下

```JavaScript
 const onClick = useCallback((name: string) => {
    setName(name);
  }, []);
```

这时即使父组件重新渲染，子组件也不会被重新渲染了。

那如果传递一个对象呢？

假设变成这样：

```JavaScript
import { useCallback, useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);
  // const [userInfo, setUserInfo] = useState({ name: "小明", age: 18 });const increment = () => setCount(count + 1);
  const userInfo = { name: "小明", age: 18 };

  return (
    <div>
        <button onClick={increment}>点击次数：{count}</button>
        <Child userInfo={userInfo} />
    </div>
  );
};
```

这时的结果是，父组件渲染，`const userInfo = { name: "小明", age: 18 };` 一行会重新生成一个新对象，导致传递给子组件的 userInfo 属性值变化，进而导致子组件重新渲染。

如果传入一个不会变的对象，子组件还是会重新渲染。

useMemo就是为了解决这个问题而生，可以理解为useMemo是对象版的useCallBack

# React.useMemo()

可以将useMemo把这个对象包裹一下

```JavaScript
const userInfo = useMemo(() => ({ name: "小明", age: 18 }), []);
```

useMemo()返回一个 memoized 值。把“创建”函数和依赖项数组作为参数传入 `useMemo`，它仅会在某个依赖项改变时才重新计算 memoized 值。

此时父组件渲染也不会导致子组件重新渲染了。

传入 `useMemo` 的函数会在渲染期间执行，不可以在这个函数内部执行与渲染无关的操作，诸如副作用这类的操作属于 `useEffect` 的适用范畴，而不是 `useMemo`。

- 如果没有提供依赖项数组，`useMemo` 在每次渲染时都会计算新的值。

# 简单总结

在子组件不需要父组件的值和函数的情况下，只需要使用memo函数包裹子组件即可。

而在使用值和函数的情况，需要考虑有函数传递给子组件则使用useCallback，传入的值有所依赖的依赖项则使用useMemo, **而不是盲目使用这些hooks。**