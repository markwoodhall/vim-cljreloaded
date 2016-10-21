if exists('g:loaded_cljreloaded') || &cp
  finish
endif
let g:loaded_cljreloaded = 1

if !exists("*fireplace#eval")
  echoerr "vim-cljreloaded requires the vim-fireplace plugin but it is not currently loaded or installed."
  finish
endif

function! s:ReloadedFunc(eval)
  let output = fireplace#echo_session_eval(a:eval, {"ns": b:cljreloaded_dev_ns})
  echo output
endfunction

if !exists('b:cljreloaded_dev_ns')
  let b:cljreloaded_dev_ns = 'dev'
  silent call s:ReloadedFunc("(in-ns 'dev)")
endif

function! s:InNs(ns)
  let b:cljreloaded_dev_ns = a:ns
  call s:ReloadedFunc("(in-ns '".a:ns.")")
endfunction

function! s:UseNs(ns)
  call s:ReloadedFunc("(use '".a:ns.")")
endfunction

function! s:System()
  let evalString = "(require '[clojure.pprint :refer [pprint]]) (pprint system)"
  call s:ReloadedFunc(evalString)
endfunction

function! s:ToList(input)
  let parsed = substitute(a:input, " ", ", ", "g")
  return eval(parsed)
endfunction

function! s:AllNs(term)
  let eval = "
              \ (use '[clojure.tools.namespace :only [find-namespaces-on-classpath]])
              \ (let [namespaces (map str (find-namespaces-on-classpath))]
              \   (vec (filter #(clojure.string/starts-with? %1 \"".a:term."\") namespaces)))"
  return s:ToList(fireplace#eval(eval))
endfunction

function! s:Reset()
  call s:ReloadedFunc("(reset)")
endfunction

function! s:ResetAll()
  call s:ReloadedFunc("(reset-all)")
endfunction

function! s:Init()
  call s:ReloadedFunc("(init)")
endfunction

function! s:Start()
  call s:ReloadedFunc("(start)")
endfunction

function! s:Stop()
  call s:ReloadedFunc("(stop)")
endfunction

function! s:Go()
  call s:ReloadedFunc("(go)")
endfunction

function! s:Refresh()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh]])(refresh)"
  call s:ReloadedFunc(evalString)
endfunction

function! s:RefreshAll()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh-all]])(refresh-all)"
  call s:ReloadedFunc(evalString)
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
    call s:ReloadedFunc(evalString)
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

autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedInNs :exe s:InNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedUseNs :exe s:UseNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -buffer ReloadedHotLoadDep :exe s:HotLoadDependency(<q-args>)
autocmd FileType clojure command! -buffer ReloadedSystem :exe s:System()
autocmd FileType clojure command! -buffer ReloadedReset :exe s:Reset()
autocmd FileType clojure command! -buffer ReloadedResetAll :exe s:ResetAll()
autocmd FileType clojure command! -buffer ReloadedInit :exe s:Init()
autocmd FileType clojure command! -buffer ReloadedStart :exe s:Start()
autocmd FileType clojure command! -buffer ReloadedStop :exe s:Stop()
autocmd FileType clojure command! -buffer ReloadedGo :exe s:Go()
autocmd FileType clojure command! -buffer ReloadedRefresh :exe s:Refresh()
autocmd FileType clojure command! -buffer ReloadedRefreshAll :exe s:RefreshAll()
autocmd FileType clojure command! -buffer ReloadedHotLoadDependencyUnderCursor :exe s:HotLoadDependencyUnderCursor()
