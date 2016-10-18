if exists('g:loaded_cljreloaded') || &cp
  finish
endif
let g:loaded_cljreloaded = 1

if !exists("*fireplace#eval")
  echoerr "vim-cljreloaded requires the vim-fireplace plugin but it is not currently loaded or installed."
  finish
endif

function! s:ReloadedFunc(eval)
  let evalString = "(in-ns 'dev) ".a:eval
  execute "Eval ".evalString
endfunction

function! s:System()
  let evalString = "(in-ns 'dev) (require '[clojure.pprint :refer [pprint]]) (pprint system)"
  execute "Eval ".evalString
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

autocmd FileType clojure command! -buffer ReloadedSystem :exe s:System()
autocmd FileType clojure command! -buffer ReloadedReset :exe s:Reset()
autocmd FileType clojure command! -buffer ReloadedResetAll :exe s:ResetAll()
autocmd FileType clojure command! -buffer ReloadedInit :exe s:Init()
autocmd FileType clojure command! -buffer ReloadedStart :exe s:Start()
autocmd FileType clojure command! -buffer ReloadedStop :exe s:Stop()
autocmd FileType clojure command! -buffer ReloadedGo :exe s:Go()
