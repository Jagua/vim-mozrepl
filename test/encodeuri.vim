

scriptencoding utf-8


let s:suite = themis#suite('decodeURI_and_encodeURI')
let s:assert = themis#helper('assert')


function! s:suite.encodeURI() abort "{{{
  call s:assert.equals(
  \ mozrepl#encodeURI('スマイルプリキュア'),
  \ '%E3%82%B9%E3%83%9E%E3%82%A4%E3%83%AB%E3%83%97%E3%83%AA%E3%82%AD%E3%83%A5%E3%82%A2')
endfunction "}}}


function! s:suite.decodeURI() abort "{{{
  call s:assert.equals(
  \ mozrepl#decodeURI('%E3%83%89%E3%82%AD%E3%83%89%E3%82%AD%E3%83%97%E3%83%AA%E3%82%AD%E3%83%A5%E3%82%A2'),
  \ 'ドキドキプリキュア')
endfunction "}}}
