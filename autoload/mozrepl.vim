

scriptencoding utf-8


let s:save_cpo = &cpo
set cpo&vim


let s:mozrepl = {}


let g:mozrepl#_default_option = {
\ 'host' : '127.0.0.1',
\ 'port' : 4242,
\ 'client' : '',
\ 'timeout' : 2000,
\ 'activate' : 1,
\ 'newtab' : 1,
\ }


" The result is a Number, which is !0 if loaded vimproc.vim, and 0 otherwise.
function! mozrepl#has_vimproc() abort "{{{
  if !exists('s:mozrepl_has_vimproc')
    try
      call vimproc#version()
      let s:mozrepl_has_vimproc = 1
    catch
      let s:mozrepl_has_vimproc = 0
    endtry
  endif
  return s:mozrepl_has_vimproc
endfunction "}}}


let g:mozrepl#_default_plugins = [
\ { 'repl_name' : 'vim',
\   'repl_function' : function('mozrepl#vim_repl'),
\   'repl_available' : has('channel') && exists('*ch_open()') },
\ { 'repl_name' : 'vimproc',
\   'repl_function' : function('mozrepl#vimproc_repl'),
\   'repl_available' : mozrepl#has_vimproc() },
\ ]


let g:mozrepl#plugin = {
\ }


function! mozrepl#new() abort "{{{
  call mozrepl#init()
  let s:mozrepl.option = {}
  return s:mozrepl
endfunction "}}}


function! s:mozrepl.client(client) abort dict "{{{
  call extend(self.option, {'client' : a:client})
  return self
endfunction "}}}


function! s:mozrepl.host(host) abort dict "{{{
  call extend(self.option, {'host' : a:host})
  return self
endfunction "}}}


function! s:mozrepl.port(port) abort dict "{{{
  call extend(self.option, {'port' : a:port})
  return self
endfunction "}}}


function! s:mozrepl.cmd(cmd) abort dict "{{{
  return mozrepl#cmd(a:cmd, self.option)
endfunction "}}}


" The result is a Dictionary.
function! mozrepl#rebuild_option(args) abort "{{{
  let option = {}
  if empty(a:args)
  elseif len(a:args) == 1 && type(a:args[0]) == type(0)
    let option = extend(option, {'port' : a:args[0]})
  elseif len(a:args) == 1 && type(a:args[0]) == type([])   " XXX: hidden feature
    let option = mozrepl#parse_option(a:args[0])
  elseif len(a:args) == 1 && type(a:args[0]) == type({})
    let option = extend(option, a:args[0])
  elseif len(a:args) == 2 && type(a:args[0]) == type('') && type(a:args[1]) == type(0)
    let option = extend(option, {'host' : a:args[0], 'port' : a:args[1]})
  elseif len(a:args) == 3 && type(a:args[0]) == type('') && type(a:args[1]) == type(0) && type(a:args[2]) == type({})
    let option = extend(option, extend({'host' : a:args[0], 'port' : a:args[1]}, a:args[2]))
  else
    echoerr 'mozrepl: unknown args ... ' . string(a:args)
  endif
  return option
endfunction "}}}


" The result is a Dictionary.
function! mozrepl#parse_option(args) abort "{{{
  let option = copy(g:mozrepl#_default_option)
  let option = extend(option, get(g:, 'mozrepl_config', {}))
  let option = extend(option, mozrepl#rebuild_option(a:args))

  if empty(option.client)
    for s in g:mozrepl#_default_plugins
      if s.repl_available
        let option.client = s.repl_name
        break
      endif
    endfor
  endif

  return extend(option, get(b:, 'mozrepl_config', {}))
endfunction "}}}


" The result is a String, which decodeURI-ed {str}.
function! mozrepl#decodeURI(str) abort "{{{
  return substitute(a:str, '%\(\x\{2}\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
endfunction "}}}


" The result is a String, which encodeURI-ed {str}.
" c.f. http://www.ecma-international.org/ecma-262/6.0/#sec-uri-syntax-and-semantics
function! mozrepl#encodeURI(str) abort "{{{
  let res = ''
  for i in range(strlen(a:str))
    let fmt = match(a:str[i],   "[;/?:@&=+$,a-zA-Z0-9\-_.!~*'()#]") ? '%%%02X' : '%c'
    let res .= printf(fmt, char2nr(a:str[i]))
  endfor
  return res
endfunction "}}}


" The result is a Dictionary. See {mozrepl-config} about {...}.
function! mozrepl#cmd(cmd, ...) abort "{{{
  let res = {}
  call mozrepl#init()
  let option = mozrepl#parse_option(a:000)
  let clients = ['vim', 'vimproc']
  if !empty(option.client) && !empty(filter(clients, 'v:val == option.client'))
    let res = s:mozrepl[option.client](a:cmd, option)
  else
    echoerr 'mozrepl: invalid client.'
  endif
  return res
endfunction "}}}


function! mozrepl#_cmd(cmdname, cmd, ...) abort "{{{
  let response = {'status' : 0, 'body' : '', 'repl_n' : ''}
  let option = mozrepl#parse_option(a:000)
  let cmd = a:cmd
  let pat_repl_n = 'To avoid conflicts, yours will be named "repl\zs\d\+\ze"'
  let pat_err = '\zs\w\+Error:.\{-}\ze\n'
  if match(cmd, 'repl\d*') != -1
    let res = call(a:cmdname, ['', option])

    " error message from MozRepl:
    "   Hmmm, seems like other repl's are running in repl context.
    "   To avoid conflicts, yours will be named "repl2".
    let repl_n = matchstr(res, pat_repl_n)
    let response.repl_n = repl_n
    let cmd = substitute(cmd, 'repl\.', 'repl' . repl_n . '\.', 'g')
  endif
  if type(a:cmdname) == type('')
    let l:Cmdname = function(a:cmdname)
  elseif type(a:cmdname) == type(function('tr'))
    let l:Cmdname = a:cmdname
  endif
  let response.body_raw = call(l:Cmdname, [cmd, option])
  let response.status = match(response.body_raw, pat_err) == -1 ? 1 : 0
  let response.repl_n = matchstr(response.body_raw, pat_repl_n)
  let response.body = matchstr(response.body_raw, '\_.\{-}repl\d*> \zs\_.*\ze\nrepl\d*>\s*')
  if match(cmd, 'repl\d*') == -1
    let response.body = substitute(response.body, '^"\(\_.*\)"$', '\1', '')
  endif
  let response.error_message = matchstr(response.body_raw, pat_err)
  return response
endfunction "}}}


" The result is a String.
" Note: timeout is not implemented.
function! mozrepl#vim_repl(cmd, ...) abort "{{{
  let res = ''
  if has('channel') && exists('*ch_open()')
    let option = mozrepl#parse_option(a:000)
    " XXX: gBrowser... is a dummy data.
    let cmd = (a:cmd == '' ? 'gBrowser.contentDocument.location.href' : a:cmd)
    let timeout = option.timeout
    try
      let handle = ch_open(option.host . ':' . string(option.port),
      \                    {'mode' : 'raw', 'timeout' : timeout})
      while match(res, 'repl\d*> ') == -1
        let res .= ch_sendraw(handle, '')
      endwhile
      let res2 = ''
      let res2 .= ch_sendraw(handle, cmd)
      while match(res2, 'repl\d*> ') == -1
        let res2 .= ch_sendraw(handle, '')
      endwhile
      let res .= res2
    catch
      let res = ''
    finally
      if exists('handle')
        call ch_close(handle)
      endif
    endtry
  else
    echoerr 'mozrepl: require +channel feature.'
  endif
  return res
endfunction "}}}


" The result is a String.
" Note: require vimproc.vim.
function! mozrepl#vimproc_repl(cmd, ...) abort "{{{
  let res = ''
  if mozrepl#has_vimproc()
    let option = mozrepl#parse_option(a:000)
    let cmd = a:cmd
    let timeout = option.timeout

    try
      let sock = vimproc#socket_open(option.host, option.port)

      while match(res, 'repl\d*> ') == -1
        let res .= sock.read(-1, timeout)
      endwhile

      let res2 = ''
      call sock.write(cmd . "\n", timeout)
      while match(res2, 'repl\d*> ') == -1
        let res2 .= sock.read(-1, timeout)
      endwhile
      let res .= res2
    catch
      let res = ''
    finally
      if exists('sock')
        call sock.close()
      endif
    endtry
  else
    echoerr 'mozrepl: require vimproc.vim.'
  endif
  return res
endfunction "}}}


"
" for omnifunc
"
function! mozrepl#javascriptcomplete(findstart, complWord) abort "{{{
  return jscomplete#CompleteJS(a:findstart, a:complWord)
endfunction "}}}


function! mozrepl#GetProperties(shortcontext) abort "{{{
  let obj = {}
  let shortcontext = a:shortcontext
  let repl_enter = 'repl.enter(' . shortcontext . ');'
  if empty(shortcontext)
    let repl_enter = ''
  endif
  let res = mozrepl#cmd(repl_enter . 'repl.look()')
  if res.status == 1
    let lines = res.body
    for line in split(lines, '\n')
      let ml = matchlist(line, '^this\.\(\w\+\)=\[\(.*\)\]$')
      if !empty(ml)
        if ml[1] =~ '^\d\+$'
          continue
        endif
        let o = {}
        if ml[2] == 'function'
          let o.kind = 'f'
        else
          let o.kind = 'v'
        endif
        let o.menu = '[]'
        let o.type = ''
        call extend(obj, {ml[1] : o})
      endif
    endfor
  endif
  return obj
endfunction "}}}


" The result is a List.
function! mozrepl#config_change_client_complete(lead, cmd, pos) abort "{{{
  return map(filter(copy(g:mozrepl#_default_plugins), 'v:val.repl_available'),
  \          'v:val.repl_name')
endfunction "}}}


function! mozrepl#config(...) abort "{{{
  let option = mozrepl#rebuild_option(a:000)
  let b:mozrepl_config = option
endfunction "}}}


function! mozrepl#register_plugin(repl_name, repl_function) abort "{{{
  if type(a:repl_name) == type('') && type(a:repl_function) == type(function('tr'))
    execute   "function! s:mozrepl." . a:repl_name . "(cmd, ...)\n"
    \       . "  let option = mozrepl#parse_option(a:000)\n"
    \       . "  return mozrepl#_cmd(" . string(a:repl_function) . ", a:cmd, option)\n"
    \       . "endfunction\n"
    let g:mozrepl#plugin[a:repl_name] = 1
  endif
endfunction "}}}


function! mozrepl#init() abort "{{{
  if empty(g:mozrepl#plugin)
    for plugin in g:mozrepl#_default_plugins
      if plugin.repl_available
        call mozrepl#register_plugin(plugin.repl_name, plugin.repl_function)
      endif
    endfor
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
