---
weight: 2
title: "Browser Working Principles"
date: 2023-03-27T13:44:28+08:00
lastmod: 2023-03-27T13:44:28+08:00
draft: false
author: "Christine Li"
images: []
resources:
- name: "featured-image"
  src: "cover.png"

tags: ["frontend", "working notes"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---


a structured summary of the **core principles of how browsers work**—from processes and threads, to caching and storage, to what really happens when a page is rendered.


<!--more-->


# Browser Working Principles

------

## 1. Browser Processes and Threads

Modern browsers adopt a multi-process architecture to ensure stability and security. The main ones include:

- **Control Process**: Coordinates, manages user interactions, and handles input.
- **Rendering Process**: The core process, each opened page is a process.
- **GPU Process**: Mainly responsible for graphics rendering and 3D rendering.

### Rendering Process (Key Point)

Each page opened in the browser is a rendering process, and each process usually contains 5 threads:

1. **GUI Rendering Thread**
   - Parses HTML, CSS, and renders the page.
   - ⚠️ **Mutually exclusive with the JS engine thread**.
2. **JS Engine Thread**
   - Handles JS code execution.
   - **The JS engine is single-threaded**.
3. **Event Trigger Thread**
   - Controls the event loop.
4. **Timer Trigger Thread**
   - Handles `setInterval` and `setTimeout`.
5. **Asynchronous HTTP Request Thread**
   - Handles asynchronous requests, places callbacks into the event queue, and finally executed by the JS engine thread.

### Interaction Between Control Process and Rendering Process

- The control process receives the user request, obtains the content, and passes it to the rendering process through the **RendererHost interface**.
- The rendering process parses and renders (relying on the above 5 threads), with assistance from the GPU process when needed.

### Web Worker

The JS engine is single-threaded, and if JS execution time is too long, it will block the page.

- The JS engine can request the browser to create a sub-thread (the sub-thread is created by the browser, fully controlled by the main thread, and cannot manipulate the DOM).
- The JS engine thread can communicate with the Worker thread.
- For very time-consuming tasks, a separate Worker thread can be created: it does not affect main thread rendering, only computes results and sends them back to the main thread — perfect!

### load Event vs. DOMContentLoaded Event

- **`DOMContentLoaded`** —— The browser has fully loaded HTML and constructed the DOM tree, but external resources like `<img>` and CSS may not be fully loaded yet.
- **`load`** —— The browser has not only loaded the HTML but also all external resources: images, styles, etc.

------

## 2. Caching Mechanism

Browser caching is divided into: **Strong Cache** and **Negotiated Cache**.

- **Strong Cache**: Directly uses local cache, no request sent (`Cache-Control`, `Expires`).
- **Negotiated Cache**: Confirms with the server whether the resource has been updated (`ETag`, `Last-Modified`).

⚠️ Usually only stores derivative files (scripts, images).

### Cache Classification

1. **Memory Cache**
   - Efficient to read, but short-lived.
   - Stores resources already fetched by the current page, such as styles, scripts, and images.
   - Released when the process is released.
   - **Closing the Tab releases the memory cache**.
2. **Disk Cache**
   - Slower to read, but larger capacity and longer persistence.
   - Most caches come from Disk Cache, set in HTTP protocol headers.

### Cache Access Priority

1. First, check **memory**. If found, load directly.
2. If not in memory, check the **disk**. If found, load directly.
3. If not in disk either, proceed with **network request**.
4. The requested resources will be cached in both disk and memory.

------

## 3. Storage Mechanism

Common browser storage methods: **Cookie, sessionStorage, localStorage**.
 Commonality: all stored on the browser side, and same-origin (same protocol, port, host).

### Cookie

HTTP Cookie is a small piece of data sent from the server to the user's browser and stored locally, automatically carried with the next request.

Features:

- Valid until expiration (keep login status/save user location, etc.).
- Transferred back and forth between browser and server, always carried in same-origin requests.
- Storage size is only **4KB**.
- Can limit path.
- Shared by all same-origin windows.

Usage:

- Session state management (user login, shopping cart, game scores, etc.).
- Personalization (themes, custom settings).
- Behavior tracking (analyzing user behavior).

Cookie fields:

- `name`, `value`
- `domain`, `path`
- `secure` (transmitted only over https)
- `httpOnly` (JS access forbidden)
- `Size` (cookie size)

Encoding method: `encodeURI()`.

**How to prevent XSS?**

- Set `httpOnly`: prohibit JS access to cookie.
- Set `secure`: cookie transmitted only via https.

### Cookie vs Session

**Why needed?**
 HTTP protocol is stateless and cannot distinguish sessions.

- Cookie: stores session id.
- Session: data stored on the server side, consuming server resources.

**Difference**:

- Cookie stored on client side, suitable for non-sensitive information.
- Session stored on server side, suitable for sensitive information (like login status).

**Session Principle**:

1. Server checks `sessionId` in request.
2. Gets server-side data based on `sessionId`.
3. If not found, create a new session and return a `sessionId` to the client.

**If the browser disables Cookie?**

1. Carry `sessionId` parameter with each request (e.g., `xxx?sessionId=123456`).
2. Use **Token mechanism** (JWT).

### SessionStorage and localStorage

- **sessionStorage**:
  - Disappears when window is closed.
  - Not shared across windows, even the same page.
- **localStorage**:
  - Permanent save (unless manually cleared).
  - Shared across same-origin windows.

### Cookie vs Token

- Cookie validation is **stateful**, server must store session.
- Token validation is **stateless**, server does not store, client saves Token (e.g., JWT).

Advantages:

- Convenient for cross-domain (only need `Access-Control-Allow-Headers: token`).
- Stateless, suitable for distributed deployment.

Usage scenarios:

- Small systems with few users: cookie/session is simpler.
- Large-scale/distributed systems: recommend token (JWT).

------

## 4. BOM (Browser Object Model)

The Browser Object Model (BOM) provides interfaces to manipulate the browser window.

Common objects:

- **location**
  - `location.href` —— returns or sets URL.
  - `location.search` —— query string part.
  - `location.hash` —— content after #.
  - `location.replace(url)` —— redirect (without recording history).
  - `location.reload()` —— reload page.
- **history**
  - `history.go(num)` —— move forward/backward by specified pages.
  - `history.back()` —— go back one page.
  - `history.forward()` —— go forward one page.

------

## 5. From Entering URL to Page Rendering

Complete process:

1. **Cache check**.
2. **DNS resolution** (may use CDN).
3. **Establish TCP connection** (three-way handshake).
4. **Send HTTP request** (if HTTPS, also SSL handshake).
5. **Server processes request** and returns response.
6. **Browser rendering**:
   1. Download HTML.
   2. Parse top-down and build DOM.
   3. Encounter CSS, start new thread to parse and build CSSOM.
   4. Encounter JS, block DOM construction, wait for JS to download and execute.
   5. DOM + CSSOM combined to generate Render Tree.
   6. Calculate layout (geometry info).
   7. Draw render tree (repaint when style changes, reflow when layout changes).

⚠️ Note:

- Render tree and DOM tree are not one-to-one, e.g., `<head>` elements will not appear in the render tree.
- Elements with `display:none` will not enter render tree.
- JavaScript may depend on CSSOM, so browser delays JS execution until CSSOM construction is complete.

Optimization order:

- **CSS first**: In resource inclusion order, CSS should come before JS.
- **JS later**: Place at the bottom of the page to avoid blocking DOM.