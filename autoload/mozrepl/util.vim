

scriptencoding utf-8


let s:save_cpo = &cpo
set cpo&vim


function! mozrepl#util#getBody(...) abort "{{{
  return mozrepl#cmd('gBrowser.contentDocument.body.innerHTML', a:000)
endfunction "}}}


function! mozrepl#util#getHtml(...) abort "{{{
  return mozrepl#cmd('gBrowser.contentDocument.getElementsByTagName("html")[0].innerHTML', a:000)
endfunction "}}}


function! mozrepl#util#getCookie(...) abort "{{{
  return mozrepl#cmd('gBrowser.contentDocument.cookie', a:000)
endfunction "}}}


function! mozrepl#util#pwd(...) abort "{{{
  return mozrepl#cmd('gBrowser.contentDocument.location.href', a:000)
endfunction "}}}


function! mozrepl#util#addTab(url, ...) abort "{{{
  let opt = {'newtab' : 1, 'activate' : 1}
  if empty(a:000)
  else
    call extend(opt, a:000[0])
  endif

  if opt.newtab == 1 && opt.activate == 1
    return mozrepl#cmd('gBrowser.selectedTab = gBrowser.addTab("' . a:url . '")', opt)
  elseif opt.newtab == 1 && opt.activate == 0
    return mozrepl#cmd('gBrowser.addTab("' . a:url . '")', opt)
  else
    return mozrepl#cmd('gBrowser.contentDocument.location.href="' . a:url . '"', opt)
  endif
endfunction "}}}


function! mozrepl#util#removeCurrentTab(...) abort "{{{
  return mozrepl#cmd('gBrowser.removeCurrentTab()', a:000)
endfunction "}}}


let &cpo = s:save_cpo
unlet s:save_cpo
