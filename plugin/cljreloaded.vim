if exists('g:loaded_cljreloaded') || &cp
  finish
endif

let g:loaded_cljreloaded = 1
let g:cljreloaded_setbindings = 1
let g:cljreloaded_bindingprefix = "cr"
let g:cljreloaded_queryclojars = 1
let g:cljreloaded_connected = 0
let g:cljreloaded_queriedclojars = 0
let g:cljreloaded_clojarsurl = "http://clojars.org/repo/all-jars.clj"
let g:cljreloaded_lasthotload = ""

let g:cljreloaded_dev_ns = "user"

if !exists("*fireplace#eval")
  echoerr "vim-cljreloaded requires the vim-fireplace plugin but it is not currently loaded or installed."
  finish
endif

function! s:SendToRepl(eval)
  let output = fireplace#session_eval(a:eval, {"ns": g:cljreloaded_dev_ns})
  echo output
endfunction

function! s:SilentSendToRepl(eval)
  let output = fireplace#session_eval(a:eval, {"ns": g:cljreloaded_dev_ns})
  return output
endfunction

function! s:ToList(input)
  let parsed = substitute(a:input, " \\.\\.\\. )", ")", "g")
  let parsed = substitute(parsed, "\" \"", "\", \"", "g")
  return eval(parsed)
endfunction

function! s:LargeOutputFromRepl(eval)
  let plength = fireplace#session_eval("*print-length*",{"ns": g:cljreloaded_dev_ns})
  call fireplace#session_eval("(set! *print-length* nil)",{"ns": g:cljreloaded_dev_ns})

  let out = fireplace#session_eval(a:eval, {"ns": g:cljreloaded_dev_ns})
  call fireplace#session_eval("(set! *print-length* ".plength.")",{"ns": g:cljreloaded_dev_ns})
  return out
endfunction

function! s:AllNs(term)
  let eval = "
              \ (try
              \   (use '[clojure.tools.namespace :only [find-namespaces-on-classpath]])
              \    1
              \   (catch Exception error 0))"

  let exists = s:SilentSendToRepl(eval)
  if exists
    let eval = "
              \ (let [namespaces (distinct (concat (map str (all-ns)) (map str (find-namespaces-on-classpath))))]
              \   (vec (filter #(clojure.string/starts-with? %1 \"".a:term."\") namespaces)))"
    let allNs = s:LargeOutputFromRepl(eval)
    return s:ToList(allNs)
  else
    echoerr "vim-cljreloaded requires org.clojure/tools.namespace >= \"0.2.11\" in order to inspect namespaces."
  endif
endfunction

function! s:InNs(ns)
  let g:cljreloaded_dev_ns = a:ns
  call s:SendToRepl("(in-ns '".a:ns.")")
endfunction

function! s:RequireNs(ns)
  call s:SendToRepl("(require ['".a:ns."])")
endfunction

function! s:UseNs(ns)
  call s:SendToRepl("(use '".a:ns.")")
endfunction

function! s:AllNsPublics(ns)
  silent call s:RequireNs(a:ns)
  let eval = "(vec (map #(clojure.string/replace (str %1) \"#'\" \"\") (vals (ns-publics '".a:ns."))))"
  let allPublics = s:LargeOutputFromRepl(eval)
  return s:ToList(allPublics)
endfunction

function! s:AllAvailableJars(term) abort
  return cljreloaded#AllAvailableJars(a:term)
endfunction

function! cljreloaded#AllAvailableJars(term)
  if !g:cljreloaded_queriedclojars
    echomsg "No data has been loaded from Clojars. This might be because there was no active REPL connection when the plugin loaded.
            \ Data will be begin downloading in the background. Try the command again in a moment."
    call s:LoadAvailableJars(1)
  endif
  let eval = "
              \ (let [jars (map #(str (first %1) \" \" (str \"\\\"\" (second %1) \"\\\"\")) @cljreloaded-jars)
              \       jars (vec (filter #(clojure.string/starts-with? %1 \"".a:term."\") jars))]
              \       jars)"

  let jars = s:LargeOutputFromRepl(eval)
  return s:ToList(jars)
endfunction

function! s:NonSnapshotJars(term)
  let eval = "
              \ (let [jars (map #(str (first %1) \" \" (str \"\\\"\" (second %1) \"\\\"\")) @cljreloaded-jars)]
              \   (vec (filter #(and (clojure.string/starts-with? %1 \"".a:term."\") (not (re-find #\"SNAPSHOT\" %1))) jars)))"
  return s:ToList(fireplace#session_eval(eval, {"ns": g:cljreloaded_dev_ns}))
endfunction

function! s:LoadAvailableJars(silent)
  let s:clojarsJarsDownload = "
    \  (defonce cljreloaded-jars (atom []))
    \  (require '[clojure.edn :as edn])
    \  (future (try (let [jars (edn/read-string (str \"[\" (slurp \"".g:cljreloaded_clojarsurl."\") \"]\"))]
    \                 (reset! cljreloaded-jars (distinct jars)))
    \            (catch Exception e (reset! cljreloaded-jars []))))"

  if a:silent
    call s:SilentSendToRepl(s:clojarsJarsDownload)
  else
    call s:SendToRepl(s:clojarsJarsDownload)
  endif
  let g:cljreloaded_queriedclojars = 1
endfunction

function! s:System()
  let evalString = "(require '[clojure.pprint :refer [pprint]]) (pprint system)"
  call s:SendToRepl(evalString)
endfunction

function! s:Reset()
  call s:SendToRepl("(reset)")
endfunction

function! s:ResetAll()
  call s:SendToRepl("(reset-all)")
endfunction

function! s:Init()
  call s:SendToRepl("(init)")
endfunction

function! s:Start()
  call s:SendToRepl("(start)")
endfunction

function! s:Stop()
  call s:SendToRepl("(stop)")
endfunction

function! s:Go()
  call s:SendToRepl("(go)")
endfunction

function! s:Refresh()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh]])(refresh)"
  call s:SendToRepl(evalString)
endfunction

function! s:RefreshAll()
  let evalString = "(require '[clojure.tools.namespace.repl :refer [refresh-all]])(refresh-all)"
  call s:SendToRepl(evalString)
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

function! s:HotLoadDepUnderCursor()
    let restorePos = getpos('.')
    call search('[', 'b')
    let cursorPos = getpos('.')
    call search(']')
    let endCursorPos = getpos('.')
    let line = getline('.')
    let dep = strpart(line, cursorPos[2], (endCursorPos[2]-1)-(cursorPos[2]))
    call s:HotLoadDependency(dep)
    call setpos('.', restorePos)
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
  if s:dump
    execute "normal! i\<CR>\<esc>\"=g:cljreloaded_lasthotload\<C-M>p"
  endif
endfunction

function! s:DependencyCompleteFzf(actions, dump) abort
  if !exists("*fzf#run")
    echoerr "DependencyCompleteFzf requires the fzf.vim plugin."
    finish
  endif
  let s:actions = a:actions
  let s:dump = a:dump
  if empty(s:actions)
    echo 'No jars found, it can take a minute or two to download completions or you might need to let g:cljreloaded_queryclojars = 1'
    return
  endif
  call fzf#run({
  \ 'source': s:actions,
  \ 'down': '40%',
  \ 'sink': function('s:DependencyCompleteFzfSink')})
endfunction

function! s:NsCompleteFzfSink(str) abort
  if s:action == "use"
    call s:UseNs(a:str)
  elseif s:action == "require"
    call s:RequireNs(a:str)
  elseif s:action == "ns"
    silent call s:RequireNs(a:str)
    let s:actions = s:AllNsPublics(a:str)
    let s:action = "publics"
    call fzf#run({
    \ 'source': s:actions,
    \ 'down': '40%',
    \ 'sink': function('s:NsCompleteFzfSink')})
    call feedkeys("i")
  elseif s:action == "publics"
    call s:SilentSendToRepl("(clojure.repl/doc ".a:str.")")
  else
    call s:InNs(a:str)
  endif
endfunction

function! s:NsCompleteFzf(actions, action) abort
  if !exists("*fzf#run")
    echoerr "NsCompleteFzf requires the fzf.vim plugin."
    finish
  endif
  let s:actions = a:actions
  let s:action = a:action
  if empty(s:actions)
    echo 'No namespaces found, clojure.tools.namespace may not be avilable.'
    return
  endif
  call fzf#run({
  \ 'source': s:actions,
  \ 'down': '40%',
  \ 'sink': function('s:NsCompleteFzfSink')})
endfunction

autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedRequireNs :call s:RequireNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedInNs :call s:InNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedUseNs :call s:UseNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:DependencyComplete -buffer ReloadedHotLoadDep :call s:HotLoadDependency(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedNsPublicsFzf :call s:NsCompleteFzf(s:AllNsPublics(<q-args>), 'publics')

autocmd FileType clojure command! -buffer ReloadedSystem :call s:System()
autocmd FileType clojure command! -buffer ReloadedReset :call s:Reset()
autocmd FileType clojure command! -buffer ReloadedResetAll :call s:ResetAll()
autocmd FileType clojure command! -buffer ReloadedInit :call s:Init()
autocmd FileType clojure command! -buffer ReloadedStart :call s:Start()
autocmd FileType clojure command! -buffer ReloadedStop :call s:Stop()
autocmd FileType clojure command! -buffer ReloadedGo :call s:Go()
autocmd FileType clojure command! -buffer ReloadedRefresh :call s:Refresh()
autocmd FileType clojure command! -buffer ReloadedRefreshAll :call s:RefreshAll()
autocmd FileType clojure command! -buffer ReloadedUseNsFzf :call s:NsCompleteFzf(s:AllNs(''), 'use')
autocmd FileType clojure command! -buffer ReloadedInNsFzf :call s:NsCompleteFzf(s:AllNs(''), 'in')
autocmd FileType clojure command! -buffer ReloadedNsFzf :call s:NsCompleteFzf(s:AllNs(''), 'ns')
autocmd FileType clojure command! -buffer ReloadedRequireNsFzf :call s:NsCompleteFzf(s:AllNs(''), 'require')
autocmd FileType clojure command! -buffer ReloadedHotLoadDepFzf :call s:DependencyCompleteFzf(s:AllAvailableJars(''), 1)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepSilentFzf :call s:DependencyCompleteFzf(s:AllAvailableJars(''), 0)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepNoSnapshotsFzf :call s:DependencyCompleteFzf(s:NonSnapshotJars(''), 1)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepNoSnapshotsSilentFzf :call s:DependencyCompleteFzf(s:NonSnapshotJars(''), 0)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepUnderCursor :call s:HotLoadDepUnderCursor()
autocmd FileType clojure command! -buffer ReloadedLoadAvailableJars :call s:LoadAvailableJars(0)

try
  let client = fireplace#platform()
  if has_key(client, 'connection')
    let g:cljreloaded_connected = 1
    let ns = fireplace#eval("
                  \  (try
                  \    (do (in-ns 'dev) (clojure.core/use 'clojure.core) (use 'dev) \"dev\")
                  \    (catch Exception e (do (in-ns 'user) \"user\")))")

    let g:cljreloaded_dev_ns = substitute(ns, "\"", "", "g")

    if g:cljreloaded_queryclojars
      call s:LoadAvailableJars(1)
    endif
  endif
catch /^Fireplace: :Connect to a REPL/
endtry


if g:cljreloaded_setbindings
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."g :ReloadedGo<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."s :ReloadedStart<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."q :ReloadedStop<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."r :ReloadedReset<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."ra :ReloadedResetAll<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."d :ReloadedHotLoadDepUnderCursor<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."ds :ReloadedHotLoadDepSilentFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."dp :ReloadedHotLoadDepFzf<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."n :ReloadedNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."un :ReloadedUseNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."in :ReloadedInNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."rn :ReloadedRequireNsFzf<CR>"
endif
