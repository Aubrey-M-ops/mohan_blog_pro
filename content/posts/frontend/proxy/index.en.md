---
weight: 3
title: "Understanding Dev Proxy: Bridging Local Development and Online Environments"
date: 2022-08-22T15:37:27+08:00
lastmod: 2022-08-22T15:37:27+08:00
draft: false
author: "Christine Li"
images: []
resources:
- name: "featured-image"
  src: "featured-image.png"

tags: ["react", "frontend", "micro-frontend architecture", "proxy"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

Dev Proxy is like a middleman that lets you debug your local code with real online data—without spinning up the whole system.

<!--more-->

## Introduction

🔹 Background

In large-scale front-end projects, the local development environment and the online environment are very different:

- Many online services are micro-frontend and distributed deployments
- Locally, developers only want to develop one sub-application, but still need to interact with other applications
- If the entire set of services has to be started locally each time, efficiency is extremely low

Therefore, there is a "proxy layer" to solve the connection between local development and the online environment.

---

🔹 What is Dev Proxy

- **Essence**: A local reverse proxy tool that can forward part of the requests to the local environment, while other requests go to the online environment.
- **Function**: Allows developers to start only the sub-application they want to debug locally, while other sub-applications still run in the online environment, keeping the overall running logic consistent with online.
- **Scenario**: Commonly used in micro-frontend projects (for example, the Garfish micro-frontend framework), where local sub-applications + online applications run together.

---

🔹 Working Principle

1. Developers start Dev Proxy locally.
2. Configure rules: which URLs go to local, which URLs are proxied to online.
3. When the browser accesses → Dev Proxy intercepts the request → applies rules → routes to local or online.
4. For developers, it looks like “running the full online environment locally.”

---

🔹 Benefits

- Greatly reduce the cost of setting up the local environment (only run the part you need to change).
- Improve debugging efficiency (real online data + local code).
- Support multi-person parallel development (each person only proxies the modules they are responsible for).

> The basic principle of Dev Proxy is that an extra layer of middleman (**HTTP Proxy**) is added between the browser and the server. The middleman transmits communication between both sides, and during the transmission, requests/responses can be modified as needed.

---

## HTTP Proxy

> HTTP proxy is the core of Dev Proxy

There are two types of HTTP proxies: `forward proxy` and `tunnel proxy`.

### Forward Proxy

The browser sends a request to the proxy server

=> The proxy server receives the **complete request** from the browser

=> The proxy server initiates a request to the real server

=> The proxy server gets the complete response

=> The response is returned to the browser

😣 Ordinary HTTP proxy cannot proxy HTTPS protocol.

---

### Tunnel Proxy

A tunnel proxy establishes a **TCP tunnel** between the browser and the server. The browser and server exchange data through the TCP tunnel created by this proxy. Tunnel proxies do not need to get the complete request/response before sending the actual request/response; instead, they forward piece by piece — **no parsing, no processing**.

😏 Any upper-layer protocol based on TCP can use tunnel proxy.

😣 But tunnel proxies cannot access the plain text of requests, so they cannot modify the contents.

> Dev Proxy needs to know the plaintext of requests, so it **cannot use a tunnel proxy directly, but must modify the tunnel proxy**.

---

### How Dev Proxy Evolves 🧐

1. The browser establishes a tunnel TCP connection (tunnel proxy) with **Dev Proxy**
2. Dev Proxy forwards the browser’s data to a **local HTTP server**
3. The local server is responsible for communicating with the real server

> The connection between the browser and the server is still a tunnel, but it changes from **(Browser <=> Proxy <=> Real Server)** to **(Browser <=> Proxy <=> Local HTTPS Server)**

😏 The local HTTPS server can then modify the request or response as needed.

---

### Root Certificate

> Why install a root certificate? 🧐

There is no secure channel between the browser and the local HTTPS server, because the local HTTPS server cannot generate certificates for domain names signed by a trusted CA.

> The role of the root certificate: issue trusted TLS certificates for any domain name, ensuring secure communication with the local HTTPS server.

=> The browser establishes a secure connection with the local HTTPS server (via the Dev Proxy root certificate). The local HTTPS server establishes a secure connection with the real server (via legitimate CA-signed certificate).

**By configuring Dev Proxy, other domains can also be proxied to local.**

For example, in a project you can proxy the online domain of `Project A` to local, then develop in the local codebase (equivalent to “modifying on the local HTTPS server”):

```
'https://xxx.com/webApp/abcabc/(.*)': `http://127.0.0.1:${PORT}/$1`,
```

Then requests are sent to BOE/PPE backend data (equivalent to “the local HTTPS server sending requests to the real server”).

---

### Master-Slave

If multiple projects are started at the same time, the “Master-Slave” mode is enabled:

- **Master**
  - Responsible for actual proxy work according to the config file
  - System proxy settings
  - HTTP service for the console
  - WebSocket service for bidirectional communication with the console
  - Update rules when Slave sends add/exit project commands
- **Slave**
  - Communicates with Master, tells Master which config file to read
  - Starts a Master process if Master is not running
- Master and Slave run in different processes. Master and Slave communicate via WebSocket. Master and the console also communicate via WebSocket.
