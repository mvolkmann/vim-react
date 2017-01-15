" This plugin defines two commands.
" The first converts a React stateless functional component
" to a class-based component.
" The second converts a React class-based component
" to a stateless functional component.

" Returns the line number of the first line found starting
" from lineNum that matches a given regular expression.
function! FindLine(startLineNum, pattern)
  let lineNum = a:startLineNum
  let lastLineNum = line('$')
  let found = 0
  while (!found && lineNum <= lastLineNum)
    let line = getline(lineNum)
    let found = line =~ a:pattern
    let lineNum += 1
  endwhile
  return found ? lineNum - 1 : 0
endfunction

function! LastToken(string)
  let tokens = split(a:string, ' ')
  return tokens[len(tokens) - 1]
endfunction

function! Trim(string)
  return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! ReactFnToClass()
  let currLineNum = line('.')
  let currLine = getline('.') " gets the entire current line
  let tokens = split(currLine, ' ')
  "for token in tokens
  "  echomsg('token = ' . token)
  "endfor

  if (tokens[0] != 'const')
    echomsg('ReactFnToClass: first token must be "const"')
    return
  endif

  if (tokens[2] != '=')
    echomsg('ReactFnToClass: third token must be "="')
    return
  endif

  let tokenCount = len(tokens)
  let lastToken = tokens[tokenCount - 1]
  let prevToken = tokens[tokenCount - 2]
  let isAF = lastToken == '=>' ||
  \ (prevToken == '=>' && lastToken == '{')
  if (!isAF)
    echomsg('ReactFnToClass: must be an arrow function')
    return
  endif

  let className = tokens[1]

  let lineNum = currLineNum
  let lastLineNum = line('$')

  if lastToken == '{'
    " Find next line that only contains "};".
    if !FindLine(lineNum, '^\w*};\w*$')
      echomsg('ReactFnToClass: arrow function end not found')
      return
    endif
  else
    " Find next line that ends with ";".
    if !FindLine(lineNum, ';\w*$')
      echomsg('ReactFnToClass: arrow function end not found')
      return
    endif
  endif

  let displayNameLine = FindLine(lineNum, '.displayName =')
  let displayName = LastToken(getline(displayNameLine))

  normal dd
  call append(currLineNum - 1, [
  \ 'class ' . className . ' extends Component {',
  \ '  static displayName = ' . displayName,
  \ '',
  \ '  static propTypes = {',
  \ '  }',
  \ '',
  \ '  render() {',
  \ '  }',
  \ '}',
  \ ])

  return

  let currColNum = col('.')

  :normal 0 " move to beginning of line

  " Search for arrow starting at the current cursor position
  " and move the cursor to the end of the match if found (e option).
  let match = search('=>', 'e', currLineNum)

  " If arrow found ...
  if match
    " If the character two past the arrow is { ...
    let currLine = getline('.') " gets the entire current line
    let index = col('.') + 1 " index of character 2 past arrow
    let char = currLine[index:index] " gets character two after match
    if char == '{'
      " Move cursor right two characters,
      " delete the open brace and the space that follows,
      " and move to the next word.
      ":normal llxxw
      :normal llxx

      let wordUnderCursor = expand('<cword>')
      if wordUnderCursor == '=>'
        " Move to next word
        :normal w
        let wordUnderCursor = expand('<cword>')
      endif

      if wordUnderCursor == 'return'
        :normal dw
      endif

      " Find the next } preceded by any amount of whitespace.
      call search('\s*}')

      " If the only thing on the line is }, delete the line
      let trimmedLine = Trim(getline('.'))
      if trimmedLine == '}' || trimmedLine == '};'
        :normal dd
      else
        :normal d$ " delete to end of line
      endif
    else
      " If nothing follows the arrow, join the next line.
      let wordUnderCursor = expand('<cword>')
      if wordUnderCursor == '=>'
        " Join next line to this one and move cursor left.
        :normal Jh
      endif

      " Add "{<cr>return" after arrow.
      :execute "normal a {\<cr>return "
      " Add } on next line.
      :execute "normal $a\<cr>};"
    endif
  else
    " Move cursor back to start.
    call cursor(currLineNum, currColNum)
    return 'not found'
  endif
endfunction

" If <leader>rf is not already mapped ...
"if mapcheck("\<leader>rf", "N") == ""
  nnoremap <leader>rc :call ReactClassToFn()<cr>
"endif

" If <leader>rc is not already mapped ...
"if mapcheck("\<leader>rc", "N") == ""
  nnoremap <leader>rc :call ReactFnToClass()<cr>
"endif
