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
let g:cljreloaded_prefix_rewriting = 0

let g:cljreloaded_dev_ns = "user"

if g:loaded_fireplace != 1
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

  let filename = tempname()
  let eval_wrapper = "(spit \"" . filename . "\"" . a:eval . ")"
  call fireplace#session_eval(eval_wrapper, {"ns": g:cljreloaded_dev_ns})
  call fireplace#session_eval("(set! *print-length* ".plength.")",{"ns": g:cljreloaded_dev_ns})

  let eval_slurp = "(slurp \"" . filename . "\")"
  let out = readfile(filename)
  call delete(filename)
  return join(out, "\n")
endfunction

function! s:AllNs(term)
  let eval = "
              \ (try
              \   (use '[clojure.tools.namespace :only [find-namespaces-on-classpath]])
              \    1
              \   (catch Exception error 0))"

  let exists = s:SilentSendToRepl(eval)
  if exists != '0'
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

function! s:AllPublics(search)
  let eval = "(vec (map str (clojure.repl/apropos \"". a:search ."\")))"
  let allPublics = s:LargeOutputFromRepl(eval)
  return s:ToList(allPublics)
endfunction

function! s:AllAvailableJars(term) abort
  return cljreloaded#AllAvailableJars(a:term)
endfunction

function! cljreloaded#AllAvailableJars(term)
  if !g:cljreloaded_queriedclojars
    echomsg "No data has been loaded from Clojars. This might be because there was no active REPL connection when the plugin loaded.
            \ Data will begin downloading in the background. Try the command again in a moment."
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
    \  (defonce cljreloaded-error (atom []))
    \  (require '[clojure.edn :as edn])
    \  (future (try (let [raw (str \"[\" (slurp \"".g:cljreloaded_clojarsurl."\") \"]\")
    \                     clean (clojure.string/replace raw #\"\\\[\\\w*/\\\d.*]\" \"\")
    \                     jars (edn/read-string clean)]
    \                 (reset! cljreloaded-jars (distinct jars)))
    \            (catch Exception e (reset! cljreloaded-jars []) (reset! cljreloaded-error e))))"

  if a:silent
    call s:SilentSendToRepl(s:clojarsJarsDownload)
  else
    call s:SendToRepl(s:clojarsJarsDownload)
  endif
  let g:cljreloaded_queriedclojars = 1
endfunction

function! s:System()
  let evalString = "(require '[clojure.pprint :refer [pprint]]) (with-out-str (pprint system))"
  call s:SendToRepl(evalString)
endfunction

function! s:Reset()
  call s:SendToRepl("(reset)")
  execute "Require!"
endfunction

function! s:ResetAll()
  call s:SendToRepl("(reset-all)")
  execute "Require!"
endfunction

function! s:Init()
  call s:SendToRepl("(init)")
  execute "Require!"
endfunction

function! s:Start()
  call s:SendToRepl("(start)")
  execute "Require!"
endfunction

function! s:Stop()
  call s:SendToRepl("(stop)")
  execute "Require!"
endfunction

function! s:Go()
  call s:SendToRepl("(go)")
  execute "Require!"
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

function! s:CleanNsUnderCursor()
  let path = expand('%')
  let prefix_rewriting = g:cljreloaded_prefix_rewriting == 1 ? 'true' : 'false'
  let new_ns = s:SilentSendToRepl("
              \ (require '[refactor-nrepl.ns.pprint :as nrepl-ns])
              \ (require '[refactor-nrepl.ns.clean-ns :as clean-ns])
              \ (refactor-nrepl.config/with-config { :prune-ns-form true :prefix-rewriting " . prefix_rewriting . " }
              \   (nrepl-ns/pprint-ns (clean-ns/clean-ns {:path \"".path."\"})))")[1:-2]
  if new_ns !~ '^(ns'
    echoerr 'There was a problem cleaning the namespace, was the cursor on the ns form?'
  elseif new_ns =~ '^(ns nil'
    echo 'ns form is already clean'
    return
  endif
  let restorePos = getpos('.')
  let endCursorPos = searchpairpos('(', '', ')')[0]
  call setpos('.', restorePos)
  execute 'd'.endCursorPos
  call setpos('.', restorePos)
  call append(0, split(new_ns, '\\n'))
  call setpos('.', restorePos)
endfunction

function! s:GetNsDefinition()
  return split(getline(1), ' ')[1]
endfunction

function! s:NewNsDefinition()
    let path = split(expand('%'), "\\.")[0]
    let clean_path = substitute(path, '^src/', '', 'g') 
    let clean_path = substitute(clean_path, '^test/', '', 'g') 
    let parts = split(clean_path, "/")
    let parts = join(parts, ".")
    let ns = substitute(parts, "/", "\\.", "g") 
    let ns = substitute(ns, "_", "-", "g") 
    return ns
endfunction

function! s:InsertNsDefinition()
  if &buftype !~# '^no' && &modifiable
    let ns = s:NewNsDefinition()

    call append(0, '(ns ' . ns . ')')
  endif
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
  \ 'window': { 'width': 0.7, 'height': 0.7 },
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
    \ 'window': { 'width': 0.7, 'height': 0.7 },
    \ 'sink': function('s:NsCompleteFzfSink')})
    call feedkeys("i")
  elseif s:action == "publics"
    let tt = s:SilentSendToRepl("(with-out-str (clojure.repl/source ".a:str."))")
    execute 'echon ' .. tt
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
  \ 'window': { 'width': 0.7, 'height': 0.7 },
  \ 'sink': function('s:NsCompleteFzfSink')})
endfunction

function! cljreloaded#all_ns()
  return s:AllNs('')
endfunction

function! cljreloaded#all_publics()
  return s:AllPublics('')
endfunction

function! cljreloaded#ns_publics(ns)
  return s:AllNsPublics(a:ns)
endfunction

function! cljreloaded#source(sym)
  return s:SilentSendToRepl("(with-out-str (clojure.repl/source ".a:sym."))")
endfunction

function! s:ReloadedSource(sym)
  let source = cljreloaded#source(a:sym)
  execute "echon " .. source
endfunction

autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedSource :call s:ReloadedSource(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedRequireNs :call s:RequireNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedInNs :call s:InNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedUseNs :call s:UseNs(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:DependencyComplete -buffer ReloadedHotLoadDep :call s:HotLoadDependency(<q-args>)
autocmd FileType clojure command! -nargs=1 -complete=customlist,s:NsComplete -buffer ReloadedNsPublicsFzf :call s:NsCompleteFzf(s:AllNsPublics(<q-args>), 'publics')


autocmd FileType clojure command! -buffer ReloadedThisNs :call s:InNs(s:GetNsDefinition())
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
autocmd FileType clojure command! -buffer ReloadedAproposFzf :call s:NsCompleteFzf(s:AllPublics(''), 'publics')
autocmd FileType clojure command! -buffer ReloadedRequireNsFzf :call s:NsCompleteFzf(s:AllNs(''), 'require')
autocmd FileType clojure command! -buffer ReloadedHotLoadDepFzf :call s:DependencyCompleteFzf(s:AllAvailableJars(''), 1)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepSilentFzf :call s:DependencyCompleteFzf(s:AllAvailableJars(''), 0)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepNoSnapshotsFzf :call s:DependencyCompleteFzf(s:NonSnapshotJars(''), 1)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepNoSnapshotsSilentFzf :call s:DependencyCompleteFzf(s:NonSnapshotJars(''), 0)
autocmd FileType clojure command! -buffer ReloadedHotLoadDepUnderCursor :call s:HotLoadDepUnderCursor()
autocmd FileType clojure command! -buffer ReloadedLoadAvailableJars :call s:LoadAvailableJars(0)

autocmd FileType clojure command! -buffer ReloadedCleanNsUnderCursor :call s:CleanNsUnderCursor()
autocmd FileType clojure command! -buffer ReloadedInsertNsDefinition :call s:InsertNsDefinition()

autocmd FileType * command! -buffer ReloadedLein :terminal lein repl
autocmd FileType * command! -buffer ReloadedClj :terminal clj -A:dev:dev/nrepl

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
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."e :Eval<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."r :Require<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."g :ReloadedGo<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."s :ReloadedStart<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."q :ReloadedStop<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."R :ReloadedReset<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."ra :ReloadedResetAll<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."d :ReloadedHotLoadDepUnderCursor<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."ds :ReloadedHotLoadDepSilentFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."dp :ReloadedHotLoadDepFzf<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."cn :ReloadedCleanNsUnderCursor<CR>"

  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."n :ReloadedNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."un :ReloadedUseNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."in :ReloadedInNsFzf<CR>"
  execute "autocmd filetype clojure nnoremap <buffer> ".g:cljreloaded_bindingprefix."rn :ReloadedRequireNsFzf<CR>"
endif

autocmd BufNewFile *.clj,*.clj[cs] :call s:InsertNsDefinition()
autocmd BufEnter *.clj,*.clj[cs] :let g:cljreloaded_dev_ns = s:GetNsDefinition()
