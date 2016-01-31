let s:save_cpo = &cpo
set cpo&vim


let s:VIMPERATOR = {
\   'kind' : 'v', 'type' : 'Object', 'props': {
\     'prototype' : {
\       'kind' : 'v', 'type' : 'Object', 'props' : {
\         'content' : {'kind' : 'v', 'menu' : '[Window]', 'type' : 'Window'},
\       },
\     },
\   },
\ }


function! js#vimperator#Extend (names)
  if !exists('b:GlobalObject')
    return
  endif

  call extend(b:GlobalObject, s:VIMPERATOR.props.prototype.props)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
