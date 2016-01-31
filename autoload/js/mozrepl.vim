let s:save_cpo = &cpo
set cpo&vim


let s:MOZREPL_GLOBAL = {
\   'kind' : 'v', 'type' : 'Object', 'menu' : '[MozRepl]', 'props': {
\   },
\ }


function! js#mozrepl#Extend (names)
  if !exists('b:GlobalObject')
    return
  endif
  let s:MOZREPL_GLOBAL.props = mozrepl#GetProperties('')
  call extend(b:GlobalObject, s:MOZREPL_GLOBAL.props)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
