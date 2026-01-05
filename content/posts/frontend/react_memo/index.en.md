---
weight: 3
title: "React - memo, useMemo, useCallback"
date: 2022-06-06T21:29:01+08:00
lastmod: 2022-06-06T21:29:01+08:00
draft: false
author: "Mohan Li"
images: []
resources:
  - name: "featured-image"
    src: "cover.png"

tags: ["react", "frontend"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

What is memo, useMemo, useCallback? and When to use them?

<!--more-->

# React - memo, useMemo, useCallback

In React, when the component's props or state changes, it will re-render. In actual development, we will encounter scenarios of unnecessary rendering. For example: the parent component:

```JavaScript
import { useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);

  return (
    <div><button onClick={()=>setCount(count + 1)}>Click count: {count}</button>
        <Child />
    </div>
  );
};
```

useState will re-render whenever the value updates. Every time `count` changes, the parent component re-renders, which causes `<Child />` to re-render as well.
**So how do we prevent the parent component's render from affecting the child component? 🧐**

# React.memo()

In the above case, you can use React.memo() to wrap the child element. `React.memo` is used to cache component renders and avoid unnecessary updates. Because React.memo “remembers” the component, **when the props it receives haven't changed, it will return the last rendered result and won't re-execute the function to return a new render result**.

```JavaScript
import { memo } from "react";

export const Child = memo(() => {
  console.log("Rendered");
  return <div>Child Component</div>;
});
```

Especially in projects where there are many dependencies, components are often re-rendered. In these cases, you can wrap the child components with memo() to reduce unnecessary renders. I've encountered an example before where rendering a long list without using memo() caused the entire list to flicker on every operation. In such situations, it can even affect visual performance.

> ❗️In the above example, the parent component simply calls the child component and does not pass any props.

What if we pass in props?

As mentioned above, this optimization depends on “unchanged props.” But if the props passed to the child component change, the child component will re-render.
**But what if the passed prop is just a function?** **In this case, it's unnecessary to re-render the child component.** For example:

```JavaScript
import { useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);
  const [name, setName] = useState("Xiao Ming");
  const increment = () => setCount(count + 1);

  const onClick = (name: string) => {
    setName(name);
  };

  return (
    <div>
        <button onClick={increment}>Click count: {count}</button>
        <Child name={name} onClick={onClick} />
    </div>
  );
};
```

If a function is passed, the child component will still re-render.

When a parent component passes a function to a child component, the parent re-renders and **recreates the onClick function**, which means the `onClick` prop passed to the child has changed, causing the child component to re-render.

So how to solve this? This is where useCallback comes in!

# React.useCallback()

Pass a callback function and a dependency array to `useCallback`, and it will return a `memoized callback function`, which **only updates when one of its dependencies changes**.

> `memoized` callback function: When a function is first called with a set of parameters, it caches the parameters and computation result. When the function is called again with the same parameters, it directly returns the cached result.

We can wrap `onClick` with useCallback:

```JavaScript
 const onClick = useCallback((name: string) => {
    setName(name);
  }, []);
```

At this point, even if the parent component re-renders, the child component will not re-render.

What if we pass an object?

Suppose it becomes like this:

```JavaScript
import { useCallback, useState } from "react";
import { Child } from "./child";

export const Parent = () => {
  const [count, setCount] = useState(0);
  // const [userInfo, setUserInfo] = useState({ name: "Xiao Ming", age: 18 });const increment = () => setCount(count + 1);
  const userInfo = { name: "Xiao Ming", age: 18 };

  return (
    <div>
        <button onClick={increment}>Click count: {count}</button>
        <Child userInfo={userInfo} />
    </div>
  );
};
```

In this case, the parent component re-renders, and the line `const userInfo = { name: "Xiao Ming", age: 18 };` creates a new object, causing the `userInfo` prop passed to the child component to change, which in turn causes the child component to re-render.

Even if we pass in a constant object, the child component will still re-render.

useMemo was created to solve this exact problem. You can think of useMemo as the object version of useCallback.

# React.useMemo()

We can wrap the object with useMemo:

```JavaScript
const userInfo = useMemo(() => ({ name: "Xiao Ming", age: 18 }), []);
```

useMemo() returns a memoized value. You pass a “creator” function and a dependency array to `useMemo`, and it only recalculates the memoized value when a dependency changes.

At this point, the parent re-rendering will no longer cause the child component to re-render.

The function passed to `useMemo` executes during render, and you **should not** perform side effects in this function — such side effects are the domain of `useEffect`, not `useMemo`.

- If no dependency array is provided, `useMemo` will calculate a new value on every render.
