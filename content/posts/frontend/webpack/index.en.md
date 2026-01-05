---
weight: 2
title: "A Practical Walkthrough of Webpack’s Core Concepts"
date: 2023-01-17T18:34:11+08:00
lastmod: 2023-01-17T18:34:11+08:00
draft: false
author: "Mohan Li"
images: []
resources:
  - name: "featured-image"
    src: "cover.png"

tags: ["react", "frontend", "webpack"]
categories: ["frontend"]

lightgallery: true

toc:
  auto: false
---

My Notes on Webpack: How It Actually Works and How to Use It

<!--more-->

## **What is Webpack**

> `Webpack` is a static module bundler for modern `JavaScript` applications, designed to efficiently manage and maintain every resource in a project.

Modern front-end development has become very complex, and we need (which is what webpack can do):

- Develop in a modular way (not only js, but also html and css)
- Use some advanced features to speed up development efficiency or improve security, such as developing script logic through ES6+ and TypeScript, and writing css style code through sass, less, etc.
- Perform compression, merging, and other related optimizations on code

When processing a program, Webpack internally builds a **dependency graph**, mapping every module required by the project, and then generates one or more **bundles** accordingly.

**Webpack can**

- Compile code (e.g. es6 => es5)
- Module integration (bundle multiple es6 files into a single bundle.js)
- Module division (supports different types of front-end modules, unified modular solutions, all resource files can be controlled via code loading) (e.g. .png/.hbs => .png, .css/.scss => .css)

## **Webpack Build Process**

> `webpack`’s running process is a serial process, and its workflow is _to connect various plugins together_. During its operation, it broadcasts events, and _plugins only need to listen to the events they care about_ to join this `webpack` mechanism and change its behavior, giving the entire system good extensibility.

### **Initialization Process**

- Read and merge parameters from the configuration file (`webpack.config.js`) and `Shell` commands to derive the final parameters.

```JavaScript
var path = require('path');
var node_modules = path.resolve(__dirname, 'node_modules');
var pathToReact = path.resolve(node_modules, 'react/dist/react.min.js');

module.exports = {
  // Entry file, the starting point of module construction, each entry corresponds to a generated chunk.
  entry: './path/to/my/entry/file.js',
  // File path alias (can speed up bundling).
  resolve: {
    alias: {
      'react': pathToReact
    }
  },
  // Output file, the endpoint of module construction, including output file and output path.
  output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js'
  },
  // Configure loaders for each module, including css preprocessors, es6 compilers, image loaders, etc.
  module: {
    loaders: [
      {
        test: /\.js$/,
        loader: 'babel',
        query: {
          presets: ['es2015', 'react']
        }
      }
    ],
    noParse: [pathToReact]
  },
  // Webpack plugin objects, executed in corresponding methods within webpack’s event flow.
  plugins: [
    new webpack.HotModuleReplacementPlugin()
  ]
};
```

- **Initialize options**: webpack copies each configuration item in `webpack.config.js` into the `options` object and loads user-configured `plugins`.
- **Initialize Compiler object**, which controls the lifecycle of `webpack`. It does not perform specific tasks but coordinates operations.

---

### **Compilation Process**

- Find all entry files based on the `entry` configuration

```JavaScript
module.exports = {
  entry: './src/file.js'
}
```

- Call the `run` method of `Compiler` to start the webpack build process:
  - `compile`: Start compilation
  - `make`: Analyze entry points and their dependent modules, create module objects
  - `build-module`: Build modules, **mainly calling configured loaders**, to transform modules into standard `JS` modules

---

### **Output Process**

- `seal`: Seal build results
  - The `seal` method generates `chunks`, optimizes them, and produces the output code
  - Assemble multiple modules into `Chunks` according to entry and dependency relationships, then convert each `Chunk` into a separate file and add it to the output list
  - `emit`: Output each chunk to the result files

```JavaScript
output: {
    path: path.resolve(__dirname, 'build'),
    filename: '[name].js'
}
```

---

## **Loader and Plugin**

### **Loader**

- By default, when encountering `import` or `require`, `webpack` only supports packaging `js` and `json` files. For types like `css`, `sass`, `png`, etc., corresponding loaders are needed to parse the content.
- When `webpack` encounters an unrecognized module, it will look for a parsing rule in the configuration.

> - Ways to configure loaders:
>   - Configuration file (recommended): specify in `webpack.config.js`
>   - Inline: explicitly specify loader in each `import` statement
>   - CLI: specify in `shell` command

- For example, using three loaders to process `.css` files:

```JavaScript
module.exports = {
  module: {
    rules: [
      {
        test: /\.css$/, // regex for matching
        use: [ // loaders to call
          { loader: 'style-loader' },
          {
            loader: 'css-loader',
            options: {
              modules: true
            }
          },
          { loader: 'sass-loader' }
        ]
      }
    ]
  }
};
```

- Common loaders:
  - css-loader: analyzes relationships between `css` modules and merges into one `css`
  - style-loader: mounts `css-loader` output into the page’s `head` via `<style>` tag
  - file-loader: moves resource modules to the output directory and returns the file path as a string

```JavaScript
rules: [
  ...,
 {
  test: /\.(png|jpe?g|gif)$/,
    use: {
      loader: "file-loader",
      options: {
        name: "[name]_[hash].[ext]", // placeholders
        outputPath: "./images",      // output directory
        publicPath: './images',      // public URL
      }
    }
 }
]
```

---

### **Plugin**

> - `Plugin` is a computer application that interacts with the main program to provide specific functionality.

- Plugins _run at different stages_ of webpack (hooks / lifecycle), _giving webpack flexible features_ such as bundling optimization, resource management, environment variable injection, etc., aiming to solve problems loaders cannot.
- A plugin is essentially a JavaScript object with an `apply` method. The parameter of `apply` is `compiler`, so the plugin can access all lifecycle hooks during compilation.

```JavaScript
const pluginName = 'ConsoleLogOnBuildWebpackPlugin';

class ConsoleLogOnBuildWebpackPlugin {
  apply(compiler) {
    compiler.hooks.run.tap(pluginName, (compilation) => {
      console.log('Webpack build process started!');
    });
  }
}

module.exports = ConsoleLogOnBuildWebpackPlugin;
```

---

### **Difference Between Loader and Plugin**

- **Concept**
  - Loader is a file loader that loads and processes resource files (e.g. compile, compress), then bundles them.
  - Plugin gives webpack flexible capabilities like optimization, resource management, and environment variable injection.
- **Runtime**
  - Loaders run before bundling files.
  - Plugins can run throughout the entire compilation lifecycle.
- **Writing loaders**
  - `this` points to webpack, so **cannot use arrow functions**
  - **Receives one parameter**: the file content passed by webpack
  - **`this` is provided by webpack**, giving access to loader information
- **Writing plugins**
  - Implement an object with an `apply` method that receives `compiler`

---

## **Webpack Hot Module Replacement**

> - `HMR` stands for `Hot Module Replacement`, meaning hot swapping of modules. It allows replacing, adding, or removing modules during runtime _without refreshing the entire application_.

- Enable HMR:

```JavaScript
const webpack = require('webpack')
module.exports = {
  // ...
  devServer: {
    // Enable HMR
    hot: true
  }
}
```

- At this point, if we modify and save a `css` file, it updates in the page without refreshing. However, if we modify and save a `js` file, the page still refreshes. Therefore, unlike other webpack features, `HMR` is not available out-of-the-box. We **need to specify which modules should perform HMR**:

```JavaScript
if(module.hot){
    module.hot.accept('./util.js',()=>{
        console.log("util.js has been updated")
    })
}
```
