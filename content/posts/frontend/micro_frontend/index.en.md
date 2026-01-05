---
weight: 2
title: "Garfish: A Micro Frontend Framework"
date: 2023-06-27T19:22:10+08:00
lastmod: 2023-06-27T19:22:10+08:00
draft: false
author: "Mohan Li"
images: []
resources:
  - name: "featured-image"
    src: "cover.png"

tags: ["react", "frontend", "micro-frontend architecture", "proxy"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

How micro frontends work and how Garfish makes it easier to plug multiple apps into one seamless product.

<!--more-->

# Introduction to Micro Frontends

## What is a Micro Frontend

It is an architectural style composed of multiple independently delivered frontend applications, decomposing a frontend application into smaller, simpler applications that can be independently developed, tested, and deployed, while still appearing as a cohesive single product to the user.

Example: In a product workbench, each module in the sidebar corresponds to a separate application, each developed independently.

TODO: Micro Frontend Example Diagram

## When to Use Micro Frontends

- Legacy project transformation. As the number of participants and teams increases and changes, an ordinary application evolves into a monolithic application, leading to the problem of the application becoming unmaintainable.

- As a portal site that needs to integrate many systems, these systems are maintained by different teams, with varying code styles and diverse technology stacks, which can only be aggregated using iframes (but not recommended 🙅♀️).

# Micro Frontend Solution: Garfish

> Garfish is a micro frontend framework

It is mainly divided into three layers: **deployment side**, **framework runtime**, and **debugging tools**. Currently, it adopts an SPA architecture.

## Why Not Use iframes

Although iframes provide isolation, they have some poor user experiences:

1. Viewport size is not synchronized (for example, one iframe’s viewport needs to be centered in the main page).
2. Communication between sub-applications is inconvenient.
3. Extra performance overhead: loading speed, building the iframe environment.

## Garfish Overall Architecture

A micro frontend framework needs to have the following functions:

1. ### Sub-application Loader (Loader)

   - - Support html-entry
   - - Preloading

   #### Loader Work

   The work of the loader is mainly divided into four steps:

   - The loader packages the sub-application into a js-bundle.
   - The sub-application exports routes.
   - Garfish-loader downloads the js-bundle, and obtains the export content of the sub-application using the commonJS specification.
   - Registers the routes into the main application.

   Implementation example:

```JavaScript
// Sub-application
export provider () {
    return {
        router: [
            {
                path: '/app2/home',
                component: Home
            },
            {
                path: '/app2/detail',
                component: Detail
            }
        ]
    };
};

// Build result
///static/app2/index.js

// Main application, download app2/index.js compile => provider
let { router } = window.Garfish.loader.loadApp('app2');
routers.push(router);
```

However, this loading mode also has some disadvantages:

- The main application and sub-applications must use the same framework.
- Sub-applications must depend on the main application to run.
- Route conflicts may occur between sub-applications.
- High business intrusiveness.
- High transformation cost for existing sub-applications.

Solution: html-entry

> ❗️We hope that it is best to **load the sub-application simply by knowing its HTML address**, instead of packaging the sub-application into a single js-bundle and loading the routes of this js sub-application.

The convention of **exporting routes** has been changed into the convention of **exporting render functions and destroy functions**.

#### Html-entry

Route-driven views!

> Browser loading page: download HTML content, parse and render HTML, load external script and style, execute scripts and styles, and draw the page.

Since we need to collect as many side effects of sub-applications as possible to avoid impacts between applications, **it is necessary to extract style and script tags that may affect the page from HTML, and handle them through the sandbox.**

Therefore, the loader’s workflow becomes:

- Fetch HTML content
- Remove unnecessary nodes such as body, head...
- Extract script and style tags for sandbox handling
- Obtain sub-application **provider** content

1. ### Sandbox Isolation (Sandbox)

- Multiple applications running simultaneously
- No impact on the main application
- Styles do not affect each other

In micro frontends, the sandbox is very important. After splitting a monolithic application into multiple sub-applications, there are many developers involved, and it is difficult to ensure that applications do not affect each other just by code and standards. What side effects need to be effectively isolated to avoid sub-applications affecting each other?

Currently, possible mutual impacts between sub-applications mainly include:

- Global environment
- Event listeners
- Timers
- Network requests
- localStorage
- Styles
- DOM operations

> 💡 Each sub-application has its own runtime environment, implementing browser-vm

#### Sandbox Implementation

> Currently there are two isolation schemes: snapshot sandbox and vm sandbox.

- Snapshot Sandbox

Take a snapshot of the current runtime environment at a certain point, and then restore the snapshot when needed to achieve isolation.

sandbox class:

```JavaScript
class Sandbox {
    private snapshotOriginal
    private snapshotMutated
    activate: () => void;
    deactivate: () => void;
}
```

1. activate: traverse variables on window and store as **snapshotOriginal**
2. deactivate: traverse window variables again, compare with **snapshotOriginal**, store differences in **snapshotMutated**, and restore window to **snapshotOriginal**
3. When switching applications again, restore **snapshotMutated** variables back to window, achieving a sandbox switch (each sandbox corresponds to a different snapshotMutated)

```JavaScript
const sandbox = new Sandbox();
sandbox.activate();
execScript(code)；
sandbox.deactivate();
```

- VM Sandbox

Create a sandbox => pass in the code to execute

```JavaScript
class VMSandbox { // create sandbox
    execScript: (code: string) => void;
    destory: () => void;
}
const sandbox = new VMSandbox();
sandbox.execScript(code)；

const sandbox2 = new VMSandbox();
sandbox2.execScript(code2)；
```

1. ### Route Management (Router)

- Route distributes applications
- Control sub-application routing

The rendering area of sub-applications is usually a fixed node. In addition to providing manual mounting, Garfish also provides the ability to bind routes to sub-applications. Users only need to **configure the application routing table**, and entering or leaving the corresponding route will **automatically trigger the mounting and destroying of sub-applications.**

How to support route management and automatically distribute sub-applications?

- Listen for route changes and distribute sub-applications
- The main application can control sub-application routing and view updates
- Main application and sub-application routes stay synchronized

## Building a Micro Frontend Application

### For the Main Application

1. First, add the dependency package.

2. In the entry of the main application, we can register sub-applications as follows:

```JavaScript
// index.js (main application entry)
import Garfish from 'garfish';
Garfish.run({
  basename: '/',
  domGetter: '#subApp',
  apps: [
    {
      name: 'react',
      activeWhen: '/react',
      entry: 'http://localhost:3000', // html entry
    },
    {
      name: 'vue',
      activeWhen: '/vue',
      entry: 'http://localhost:8080/index.js', // js entry
    },
  ],
});
```

When the Garfish instance is imported and the `Garfish.run` method is executed, `Garfish` immediately enables route hijacking, listens for browser route changes, and executes matching logic.

When the current path matches the sub-application logic, it will automatically mount the application to the specified `dom` node, and during this process, it will sequentially trigger the lifecycle hooks of sub-application loading and rendering.

### For the Sub-application

1. Adjust the build configuration of the sub-application (the configuration exported in webpack.config.js or vite.config.js).

2. Export the provider function.

   1. You can use the `@garfish/bridge-react` mentioned in the official documentation.
   2. You can customize the export function (below is the official example). You must provide a `render function` and a `destroy function`, so that the sub-application can be rendered and destroyed when entering or exiting a route.

   ```JavaScript
   import React from 'react';
   import ReactDOM from 'react-dom';
   import { BrowserRouter, Switch, Route, Link } from 'react-router-dom';

   export const provider = () => ({
     // render function, must be provided
     render: ({ dom, basename }) => {
       ReactDOM.render(
         <React.StrictMode>
           <App basename={basename} />
         </React.StrictMode>,
         dom.querySelector('#root'),
       );
     },
     // destroy function, must be provided
     destroy: ({ dom, basename }) => {
       ReactDOM.unmountComponentAtNode(
         dom ? dom.querySelector('#root') : document.querySelector('#root'),
       );
     },
   });
   ```

3. Set the basename of the route.

   1. **If the sub-application has its own routes, in the micro frontend scenario, the basename must be used as the base path of the sub-application. Without a base route, the sub-application routes may conflict with the main application or other applications.**

- Why?

- - Currently, the main application is accessed at `garfish.bytedance.com`, so the current `basename` is `/`. The sub-application vue can be accessed at `garfish.bytedance.com/vue`.
  - If the main application changes `basename` to `/site`, then the main application access path becomes `garfish.bytedance.com/site`, and the sub-application vue access path becomes `garfish.bytedance.com/site/vue`.
  - Therefore, it is recommended that sub-applications directly use the `basename` passed in `provider` as the base route of their own application, ensuring that when the main application changes its route, **the relative path of the sub-application still follows the overall change.**

### Simple Summary

- Main Application Setup

  - Register basic information of sub-applications
  - Use Garfish to schedule and manage sub-applications in the main application

- Sub-application Modification

  - Add corresponding build configuration
  - Export the `provider` function by wrapping the sub-application with the function provided by the `@garfish/bridge-react` package
  - Add basename settings for different framework types:

    - React: pass `basename` into `BrowserRouter`’s `basename` property in the root component
    - Vue: pass `basename` into `VueRouter`’s `basename` property
