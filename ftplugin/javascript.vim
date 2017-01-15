" This plugin defines two commands.
" The first converts a React stateless functional component
" to a class-based component.
" The second converts a React class-based component
" to a stateless functional component.

function! DeleteLines(start, end)
  " Without silent the deletion is reported in the status bar.
  execute 'silent ' . a:start . ',' . a:end . 'd'
endf

function! LogList(label, list)
  echomsg(a:label)
  for item in a:list
    echomsg('  ' . item)
  endfor
endf

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
  endwhile
  return lines
endf

function! LastToken(string)
  let tokens = split(a:string, ' ')
  return tokens[len(tokens) - 1]
endf

function! Trim(string)
  return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf

function! ReactFnToClass()
  let currLineNum = line('.')
  let currLine = getline('.') " gets the entire current line
  let tokens = split(currLine, ' ')

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

  let renderLines = GetLinesTo(currLineNum + 1, ';$')
  call DeleteLines(currLineNum, currLineNum + len(renderLines))
  let index = len(renderLines) - 1
  let lastRenderLine = renderLines[index]
  if lastRenderLine =~ ';$'
    let renderLines[index] = lastRenderLine[0:-2]
  endif

  let displayNameLineNum = FindLine(lineNum, className . '.displayName =')
  if displayNameLineNum
    let displayName = LastToken(getline(displayNameLineNum))
    call DeleteLines(displayNameLineNum, displayNameLineNum)
  endif

  let propTypesLineNum = FindLine(lineNum, className . '.propTypes =')
  if propTypesLineNum
    let propTypes = GetLinesTo(propTypesLineNum + 1, '.*};')
    let propNames = []
    for line in propTypes
      let propName = Trim(split(line, ':')[0])
      if propName != '};'
        call add(propNames, propName)
      endif
    endfor
    call DeleteLines(propTypesLineNum, propTypesLineNum + len(propTypes))
  endif

  let lines = ['class ' . className . ' extends Component {']

  if exists('displayName')
    let lines += [
    \ '  static displayName = ' . displayName,
    \ ''
    \ ]
  endif

  if exists('propTypes')
    call add(lines, '  static propTypes = {')
    for line in propTypes
      call add(lines, '  ' . line)
    endfor
    call add(lines, '')
  endif

  call add(lines, '  render() {')

  if exists('propTypes')
    call add(lines,
    \ '    const {' . join(propNames, ', ') . '} = this.props;')
  endif

  call add(lines, '    return (')

  for line in renderLines
    call add(lines, '    ' . line)
  endfor

  let lines += [
  \ '    );',
  \ '  }',
  \ '}',
  \ ]

  "call LogList('lines', lines)

  call append(currLineNum - 1, lines)
endf

" If <leader>rf is not already mapped ...
"if mapcheck("\<leader>rf", "N") == ""
  nnoremap <leader>rc :call ReactClassToFn()<cr>
"endif

" If <leader>rc is not already mapped ...
"if mapcheck("\<leader>rc", "N") == ""
  nnoremap <leader>rc :call ReactFnToClass()<cr>
"endif
