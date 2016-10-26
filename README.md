## Purpose

To have a better [reloaded](http://thinkrelevance.com/blog/2013/06/04/clojure-workflow-reloaded) workflow when using vim.

This plugin makes available the functions defined by the [reloaded.repl](https://github.com/weavejester/reloaded.repl) for use with Stuart Sierra's [component](https://github.com/stuartsierra/component).

For hot loading dependencies this plugin makes use of [cemerick.pomegranate](https://github.com/cemerick/pomegranate).

You can add these as dependencies using a `:dev` profile in `project.clj` or by adding them to `~/.lein/profiles.clj`.

Note. There is no hard requirement to use [reloaded.repl](https://github.com/weavejester/reloaded.repl) and/or [cemerick.pomegranate](https://github.com/cemerick/pomegranate)
but certain functionality requires it. If you try to use some of this functionality without those dependencies being available you should get
an error message indicating what is required.

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
Pretty prints the `system`.

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

### `:ReloadedInNsFzf`
Changes `*ns*` in the underlying nREPL session to be `$namespace`. Supports selection of the namespace using a list of available namespaces on the
classpath as a source for the [fzf.vim selector](https://github.com/junegunn/fzf.vim).

![In ns example](http://i.imgur.com/NutK0fZ.png)

### `:ReloadedUseNs`
Calls `(use '$namespace)` in the underlying nREPL session. Supports tab completion on the namespace using namespaces
currently available on the classpath.

![Use ns example](http://i.imgur.com/SZepWw6.png)

### `:ReloadedUseNsFzf`
Calls `(use '$namespace)` in the underlying nREPL session. Supports selection of the namespace using a list of available namepaces on the
classpath as a source for the

![Use ns example](http://i.imgur.com/JhNd4wi.png)

### `:ReloadedHotLoadDepUnderCursor`

vim-cljreloaded can hot load dependencies into a running nREPL session using [pomegranate](https://github.com/cemerick/pomegranate).

![Hot load example](http://i.imgur.com/H15hdFM.png)

In the above example I had the following mapping in place.

```vim
autocmd filetype clojure nnoremap <buffer> hld :ReloadedHotLoadDependencyUnderCursor<CR>
```

### `:ReloadedHotLoadDep`

Hot load a specified dependency into a running nREPL session. Supports tab completions on the dependency using a list
of jars from [Clojars](https://clojars.org/).

![Hot load example](http://i.imgur.com/lgjVs0P.png)

### `:ReloadedHotLoadDepFzf`

Hot load a specified dependency into a running nREPL session. Supports selection of the dependency using a list
of jars from [Clojars](https://clojars.org/) as a source for the [fzf.vim selector](https://github.com/junegunn/fzf.vim).

![Hot load example](http://i.imgur.com/VNRpPpp.png)

Note. This works best when your cursor is positioned on the closing square bracket of the `:dependencies` value.

### `:ReloadedHotLoadDepSilentFzf`

This is the same as above but it will not output anything to the current buffer.

### `:ReloadedHotLoadDepNoSnapshotsFzf`

This is the same as `:ReloadedHotLoadDepFzf` but `SNAPSHOT` jars are automatically filtered out.

![Hot load example](http://i.imgur.com/gYPPmZY.png)

### `:ReloadedHotLoadDepNoSnapshotSilentFzf`

This is the same as above but it will not output anything to the current buffer.

### Notes about hot loading and completion

It is worth pointing out that as it currently stands any command that hot loads a dependency will block until the dependency and all its requirements have downloaded.

It is also worth noting that dependency completions are a bit of a hack at the moment. When enabled the plugin will request data from the [all-jars.clj](https://clojars.org/repo/all-jars.clj) endpoint
provided by [Clojars](https://clojars.org/). The data is currently just over **4mb** and is built by [Clojars](https://clojars.org/) every hour, it is loaded into a running nREPL session asynchronously, it is then used as a completion source. At somepoint it would be sensible
to change to use "real time" searching of Clojars but this is working for me now, so I've made it available.

Once the data is downloaded it won't be downloaded again until the plugin is reloaded or you manually call `:ReloadedLoadAvailableJars`.

Fetching data from [Clojars](https://clojars.org/) is enabled by default but can be disabled with the following.

```vim
let g:cljreloaded_queryclojars = 0
```

If you need to use a different source for available jars then you can set the following.

```vim
let g:cljreloaded_clojarsurl = "http://clojars.org/repo/all-jars.clj"
```

## License
Copyright © Mark Woodhall. Distributed under the same terms as Vim itself. See `:help license`
