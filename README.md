## Purpose

To have a better [reloaded](http://thinkrelevance.com/blog/2013/06/04/clojure-workflow-reloaded) workflow when using vim.

This plugin makes available the functions defined by the [reloaded.repl](https://github.com/weavejester/reloaded.repl) for use with Stuart Sierras [component](https://github.com/stuartsierra/component).

For hot loading dependencies this plugin makes use of [cemerick.pomegranate](https://github.com/cemerick/pomegranate).

You can add these as dependencies using a `:dev` profile in `project.clj` or by adding them to `~/.lein/profiles.clj`.

## Installation

Install using your favourite plugin manager,
I use [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'markwoodhall/vim-cljreloaded'
```

## Requirements

This plugin makes use of [vim-fireplace](https://github.com/tpope/vim-fireplace) so you will need to install this as well.

```vim
Plug 'tpope/vim-fireplace'

```

As is typical for [vim-fireplace](https://github.com/tpope/vim-fireplace) you will need a running REPL, `lein repl`.

It is typical to have a `dev.clj` and a `dev` namespace that exposes these functions and sets the function used to start the system. For example.

```clojure
(ns dev
  "Tools for interactive development with the REPL. This file should
  not be included in a production build of the application."
  (:require [com.stuartsierra.component :as component]
            [component-test.system :refer [new-system]]
            [reloaded.repl :refer [system init start stop go reset reset-all]]))

(reloaded.repl/set-init! #(new-system {:port 8080 :host "localhost"}))

```

## Usage

The following functions are made available:

### `:ReloadedStart`
Calls the `(start)` function defined by `reloaded.repl`.

![Start example](http://i.imgur.com/elNZsQI.png)

### `:ReloadedStop`
Calls the `(stop)` function defined by `reloaded.repl`.

![Stop example](http://i.imgur.com/YAoPAC9.png)

### `:ReloadedReset`
Calls the `(reset)` function defined by `reloaded.repl`.

![Reset example](http://i.imgur.com/sZfASZl.png)

### `:ReloadedResetAll`
Calls the `(reset-all)` function defined by `reloaded.repl`.

![Reset all example](http://i.imgur.com/vqkZoXV.png)

### `:ReloadedInit`
Calls the `(init)` function defined by `reloaded.repl`.

![Init example](http://i.imgur.com/GSiDOru.png)

### `:ReloadedGo`
Calls the `(go)` function defined by `reloaded.repl`.

![Go example](http://i.imgur.com/rALjXYy.png)

### `:ReloadedSystem`
Pretty prints the system

![System example](http://i.imgur.com/QjrkGHG.png)

**The functions below are not strictly `reloaded.repl` related but they may enhance a "reloaded" workflow in vim.**

### `:ReloadedRefresh`
Calls the `(refresh)` function defined by `clojure.tools.namespace.repl`

![Refresh example](http://i.imgur.com/PGOF063.png)

### `:ReloadedRefreshAll`
Calls the `(refresh-all)` function defined by `clojure.tools.namespace.repl`

![Refresh all example](http://i.imgur.com/X8e6W5X.png)

### `:ReloadedInNs`
Changes `*ns*` in the underlying nREPL session to be `$namespace`. Supports tab completion on the namespace using namespaces
currently available on the classpath.

![In ns example](http://i.imgur.com/NP4zckP.png)

### `:ReloadedUseNs`
Calls `(use '$namespace)` in the underlying nREPL session. Supports tab completion on the namespace using namespaces
currently available on the classpath.

![Use ns example](http://i.imgur.com/UxIM1NF.png)

### `:ReloadedHotLoadDependencyUnderCursor`

vim-cljreloaded can hot load dependencies into a running nREPL session using [pomegranate](https://github.com/cemerick/pomegranate).

![Hot load example](http://i.imgur.com/H15hdFM.png)

In the above example I had the following mapping in place.

```vim
autocmd filetype clojure nnoremap <buffer> hld :ReloadedHotLoadDependencyUnderCursor<CR>
```

## License
Copyright © Mark Woodhall. Distributed under the same terms as Vim itself. See `:help license`
