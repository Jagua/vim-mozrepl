

scriptencoding utf-8


let s:save_cpo = &cpo
set cpo&vim


command! -nargs=+ -complete=customlist,mozrepl#config_change_client_complete MozReplConfigChangeClient call mozrepl#config({'client' : <q-args>})
command! -nargs=1 -complete=customlist,mozrepl#jscomplete_line MozReplCmd call mozrepl#cmd(<q-args>)
command! -nargs=1 -complete=customlist,mozrepl#jscomplete_line MozReplEcho echo mozrepl#cmd(<q-args>).body


function! mozrepl#jscomplete_line(lead, cmd, pos) abort "{{{
  let s = copy(a:lead)
  let s = substitute(s, '^\(.\{-}\)\[\(.\{-}\)\]\(.*\)$', '\=submatch(1).repeat("x", len(submatch(2))+2).submatch(3)', 'g')
  let s = substitute(s, '^\(.\{-}\)"\(.\{-}\)"\(.*\)$', '\=submatch(1).repeat("x", len(submatch(2))+2).submatch(3)', 'g')
  let s = substitute(s, '^\(.*\)"\(.\{-}\)$', '\=submatch(1).repeat("x", len(submatch(2))+1)', 'g')

  if strridx(s, '[') != -1 && strridx(s, '.') != -1 && (strridx(s, '[') > strridx(s, '.'))
    let delimiter = '['
  else
    let delimiter = '.'
  endif
  let shortcontext = strpart(a:lead, 0, strridx(s, delimiter) + 1)
  let complWord = strpart(a:lead, strridx(s, delimiter) + 1)

  if shortcontext == ''
    let repl_enter = ''
  else
    let repl_enter = 'repl.enter(' . shortcontext[0 : len(shortcontext) - 2] . ');'
  endif

  if shortcontext == 'content.'
    return map(copy(jscomplete#GetCompleteWords(complWord, shortcontext, 0, 0)), 'shortcontext . v:val')
  else
    let list = mozrepl#cmd(repl_enter . 'repl.search(/^' . complWord . '/i)').body
    return map(sort(split(list, '\n')), 'shortcontext . v:val')
  endif

  if stridx(shortcontext, 'liberator.') != -1
    let s = strpart(a:lead, 0, strridx(a:lead, '.') + 1)
    let c = strpart(a:lead, strridx(a:lead, '.') + 1)
    if s[len(s) - 1] == '.'
      let s = s[0 : len(s) - 2]
    endif
    let list = mozrepl#cmd('repl.enter(' . s . ');repl.search(/^' . c . '/i)').body
    return map(sort(split(list, '\n')), 'shortcontext . v:val')
  else
    return map(copy(jscomplete#GetCompleteWords(complWord, shortcontext, 0, 0)), 'shortcontext . v:val')
  endif
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
