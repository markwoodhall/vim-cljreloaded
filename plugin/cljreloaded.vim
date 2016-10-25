if exists('g:loaded_cljreloaded') || &cp
  finish
endif

let g:loaded_cljreloaded = 1
let g:cljreloaded_queryclojars = 1
let g:cljreloaded_clojarsurl = "http://clojars.org/repo/all-jars.clj"
let g:cljreloaded_lasthotload = ""

if !exists("*fireplace#eval")
  echoerr "vim-cljreloaded requires the vim-fireplace plugin but it is not currently loaded or installed."
  finish
endif

function! s:SendToRepl(eval)
  let output = fireplace#session_eval(a:eval, {"ns": s:cljreloaded_dev_ns})
  echo output
endfunction

function! s:SilentSendToRepl(eval)
  call fireplace#session_eval(a:eval, {"ns": s:cljreloaded_dev_ns})
endfunction

function! s:ToList(input)
  let parsed = substitute(a:input, "\" \"", "\", \"", "g")
  return eval(parsed)
endfunction

function! s:AllNs(term)
  let eval = "
              \ (try
              \   (use '[clojure.tools.namespace :only [find-namespaces-on-classpath]])
              \   (catch Exception error []))"

  let exists = fireplace#eval(eval)
  if exists == "nil"
    let eval = "
              \ (let [namespaces (map str (find-namespaces-on-classpath))]
              \   (vec (filter #(clojure.string/starts-with? %1 \"".a:term."\") namespaces)))"
    return s:ToList(fireplace#eval(eval))
  else
    echoerr "vim-cljreloaded requires org.clojure/tools.namespace >= \"0.2.11\" in order to inspect namespaces."
  endif
endfunction

function! s:SendToReloadedRepl(eval)
  if s:AllNs("reloaded.repl") == []
    echoerr "vim-cljreloaded requires reloaded.repl >= \"0.2.3\" in order to use reloaded workflow functions."
  else
    let output = fireplace#session_eval(a:eval, {"ns": s:cljreloaded_dev_ns})
    echo output
  endif
endfunction

function! s:SilentSendToReloadedRepl(eval)
  if s:AllNs("reloaded.repl") == []
    echoerr "vim-cljreloaded requires reloaded.repl >= \"0.2.3\" in order to use reloaded workflow functions."
  else
    call fireplace#session_eval(a:eval, {"ns": s:cljreloaded_dev_ns})
  endif
endfunction

if !exists('s:cljreloaded_dev_ns')
  let ns = fireplace#eval("
                \  (try
                \    (do (in-ns 'dev) (clojure.core/use 'clojure.core) (use 'dev) \"dev\")
                \    (catch Exception e (do (in-ns 'user) \"user\")))")

  let s:cljreloaded_dev_ns = substitute(ns, "\"", "", "g")
endif

function! s:InNs(ns)
  let s:cljreloaded_dev_ns = a:ns
  call s:SendToRepl("(in-ns '".a:ns.")")
endfunction

function! s:UseNs(ns)
  call s:SendToRepl("(use '".a:ns.")")
endfunction

function! s:AllAvailableJars(term)
  let eval = "
              \ (let [jars (map #(str (first %1) \" \" (str \"\\\"\" (second %1) \"\\\"\")) @cljreloaded-jars)]
              \   (vec (filter #(clojure.string/starts-with? %1 \"".a:term."\") jars)))"
  return s:ToList(fireplace#session_eval(eval, {"ns": s:cljreloaded_dev_ns}))
endfunction

function! s:NonSnapshotJars(term)
  let eval = "
              \ (let [jars (map #(str (first %1) \" \" (str \"\\\"\" (second %1) \"\\\"\")) @cljreloaded-jars)]
              \   (vec (filter #(and (clojure.string/starts-with? %1 \"".a:term."\") (not (re-find #\"SNAPSHOT\" %1))) jars)))"
  return s:ToList(fireplace#session_eval(eval, {"ns": s:cljreloaded_dev_ns}))
endfunction

function! s:LoadAvailableJars(silent)
  let s:clojarsJarsDownload = "
    \  (def cljreloaded-jars (atom []))
    \  (future (let [jars (read-string (str \"[\" (slurp \"".g:cljreloaded_clojarsurl."\") \"]\"))]
    \            (reset! cljreloaded-jars (distinct jars))))"

  if a:silent
    call s:SilentSendToRepl(s:clojarsJarsDownload)
  else
    call s:SendToRepl(s:clojarsJarsDownload)
  endif
endfunction

function! s:System()
  let evalString = "(require '[clojure.pprint :refer [pprint]]) (pprint system)"
  call s:SendToReloadedRepl(evalString)
endfunction

function! s:Reset()
  call s:SendToReloadedRepl("(reset)")
endfunction

function! s:ResetAll()
  call s:SendToReloadedRepl("(reset-all)")
endfunction

function! s:Init()
  call s:SendToReloadedRepl("(init)")
endfunction

function! s:Start()
  call s:SendToReloadedRepl("(start)")
endfunction

function! s:Stop()
  call s:SendToReloadedRepl("(stop)")
endfunction

function! s:Go()
  call s:SendToReloadedRepl("(go)")
endfunction

function! s:Refresh()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh]])(refresh)"
  call s:SendToReloadedRepl(evalString)
endfunction

function! s:RefreshAll()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh-all]])(refresh-all)"
  call s:SendToReloadedRepl(evalString)
endfunction

function! s:HotLoadDependency(dependency)
  if s:AllNs("cemerick.pomegranate") == []
    echoerr "vim-cljreloaded requires com.cemerick/pomegranate >= \"0.3.1\" in order to hot load dependencies."
  else
    let evalString = "
                      \ (use '[cemerick.pomegranate :only (add-dependencies)])
                      \ (add-dependencies
                      \   :coordinates '[[".a:dependency."]]
                      \   :repositories (merge cemerick.pomegranate.aether/maven-central
                      \                 {\"clojars\" \"http://clojars.org/repo\"}))"
    let g:cljreloaded_lasthotload = "[".a:dependency."]"
    call s:SendToRepl(evalString)
  endif
endfunction

function! s:HotLoadDependencyUnderCursor()
    let cursorPos = getpos('.')
    call search(']')
    let endCursorPos = getpos('.')
    let line = getline('.')
    let dep = strpart(line, cursorPos[2]-1, (endCursorPos[2]-1)-(cursorPos[2]-1))
    call s:HotLoadDependency(dep)
    call setpos('.', cursorPos)
endfunction

function! s:NsComplete(A, L, P) abort
  if strpart(a:L, 0, a:P) !~# ' [[:alnum:]-]\+ '
    let cmds = s:AllNs(a:A)
    return filter(cmds, 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
  endif
endfunction

function! s:DependencyComplete(A, L, P) abort
  if strpart(a:L, 0, a:P) !~# ' [[:alnum:]-]\+ '
    let cmds = s:AllAvailableJars(a:A)
    return filter(cmds, 'strpart(v:val, 0, strlen(a:A)) ==# a:A')
  endif
endfunction

function! s:DependencyCompleteFzfSink(str) abort
  call s:HotLoadDependency(a:str)
endfunction

function! s:DependencyCompleteFzf(actions) abort
  if !exists("*fzf#run")
    echoerr "DependencyCompleteFzf requires the fzf.vim plugin."
    finish
  endif
  let s:actions = a:actions
  if empty(s:actions)
    echo 'No jars found, it can take a minute or two to download completions or you might need to let g:cljreloaded_queryclojars = 1'
    return
  endif
  call fzf#run({
  \ 'source': s:actions,
  \ 'down': '40%',
  \ 'sink': function('s:DependencyCompleteFzfSink')})
endfunction

autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedInNs :exe s:InNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedUseNs :exe s:UseNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:DependencyComplete -buffer ReloadedHotLoadDep :exe s:HotLoadDependency(<q-args>)

autocmd FileType clojure command! -buffer ReloadedSystem :exe s:System()
autocmd FileType clojure command! -buffer ReloadedReset :exe s:Reset()
autocmd FileType clojure command! -buffer ReloadedResetAll :exe s:ResetAll()
autocmd FileType clojure command! -buffer ReloadedInit :exe s:Init()
autocmd FileType clojure command! -buffer ReloadedStart :exe s:Start()
autocmd FileType clojure command! -buffer ReloadedStop :exe s:Stop()
autocmd FileType clojure command! -buffer ReloadedGo :exe s:Go()
autocmd FileType clojure command! -buffer ReloadedRefresh :exe s:Refresh()
autocmd FileType clojure command! -buffer ReloadedRefreshAll :exe s:RefreshAll()
autocmd FileType clojure command! -buffer ReloadedHotLoadDepFzf :exe s:DependencyCompleteFzf(s:AllAvailableJars(''))
autocmd FileType clojure command! -buffer ReloadedHotLoadDepNoSnapshotsFzf :exe s:DependencyCompleteFzf(s:NonSnapshotJars(''))
autocmd FileType clojure command! -buffer ReloadedHotLoadDependencyUnderCursor :exe s:HotLoadDependencyUnderCursor()
autocmd FileType clojure command! -buffer ReloadedLoadAvailableJars :exe s:LoadAvailableJars(0)

if g:cljreloaded_queryclojars
  call s:LoadAvailableJars(1)
endif
