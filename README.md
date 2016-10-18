## Purpose

This plugin makes available the functions defined by the [reloaded.repl](https://github.com/weavejester/reloaded.repl) for use with Stuart Sierras [component](https://github.com/stuartsierra/component).

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

In it typical to have a `dev.clj` and a `dev` namespace that exposes these functions and starts the system. For example.

```clojure
tns dev
  "Tools for interactive development with the REPL. This file should
  not be included in a production build of the application."
  (:require [com.stuartsierra.component :as component]
            [component-test.system :refer [new-system]]
            [reloaded.repl :refer [system init start stop go reset reset-all]]))

(reloaded.repl/set-init! #(new-system {:port 8080 :host "localhost"}))

```

## Usage

The following functions are made available:

```vim
:ReloadedStart
:ReloadedStop
:ReloadedReset
:ReloadedResetAll
:ReloadedInit
:ReloadedGo
```

The above functions map to the functions defined by reloaded.repl.

```clojure
 (start)
 (stop)
 (reset)
 (reset-all)
 (init)
 (go)
 ```

## License
Copyright © Mark Woodhall. Distributed under the same terms as Vim itself. See `:help license`
