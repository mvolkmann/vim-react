" This file name is an abbreviation for "Vim React Utilities".

function! DeleteLine(lineNum)
  call DeleteLines(a:lineNum, a:lineNum)
endf

function! DeleteLineIfBlank(lineNum)
  if (len(Trim(getline(a:lineNum))) == 0)
    execute 'silent ' . a:lineNum . 'd'
  endif
endf

function! DeleteLines(start, end)
  " Without silent the deletion is reported in the status bar.
  execute 'silent ' . a:start . ',' . a:end . 'd'
endf

" Returns the line number of the next line found starting
" from lineNum that matches a given regular expression
" or zero of none is found.
function! FindNextLine(startLineNum, pattern)
  let lineNum = a:startLineNum
  let lastLineNum = line('$')
  let found = 0
  while (!found && lineNum < lastLineNum)
    let line = getline(lineNum)
    let found = line =~# a:pattern
    let lineNum += 1
  endw
  return found ? lineNum - 1: 0
endf

" Returns the line number of the previous line found starting
" from lineNum that matches a given regular expression
" or zero of none is found.
function! FindPreviousLine(startLineNum, pattern)
  let lineNum = a:startLineNum
  let found = 0
  while (!found && lineNum > 0)
    let line = getline(lineNum)
    let found = line =~# a:pattern
    let lineNum -= 1
  endw
  return found ? lineNum + 1: 0
endf

" Returns the line number of the first line found starting
" from lineNum that matches a given regular expression
" or zero of none is found.
function! FindNextLine(startLineNum, pattern)
  let lineNum = a:startLineNum
  let lastLineNum = line('$')
  let found = 0
  while (!found && lineNum < lastLineNum)
    let line = getline(lineNum)
    let found = line =~ a:pattern
    let lineNum += 1
  endw
  return found ? lineNum - 1: 0
endf

function! GetLinesTo(startLineNum, pattern)
  let lines = []
  let lineNum = a:startLineNum
  let lastLineNum = line('$')
  let found = 0
  while (!found && lineNum <= lastLineNum)
    let line = getline(lineNum)
    let found = line =~ a:pattern
    call add(lines, line)
    let lineNum += 1
  endw
  return lines
endf

function! LastToken(string)
  let tokens = split(a:string, ' ')
  return tokens[len(tokens) - 1]
endf

function! LogList(label, list)
  echo a:label
  for item in a:list
    echo '  ' . len(item) . ': ' . item
  endfor
endf

" Returns the nth token in a string
" where the first token is 1.
function! NthToken(n, string)
  let tokens = split(a:string, ' ')
  return tokens[a:n - 1]
endf

function! PopList(list)
  let index = len(a:list) - 1
  let last = a:list[index]
  call remove(a:list, index)
  return last
endf

function! Trim(string)
  return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf

function! TrimTrailing(string)
  return substitute(a:string, '^(\s*\.\{-}\)\s*$', '\1', '')
endf

