" This plugin defines two commands.
" The first converts a React stateless functional component
" to a class-based component.
" The second converts a React class-based component
" to a stateless functional component.

function! DeleteLineIfBlank(lineNum)
  if (len(Trim(getline(a:lineNum))) == 0)
    execute 'silent ' . a:lineNum . 'd'
  endif
endf

function! DeleteLines(start, end)
  " Without silent the deletion is reported in the status bar.
  execute 'silent ' . a:start . ',' . a:end . 'd'
endf

" Returns the line number of the first line found starting
" from lineNum that matches a given regular expression
" or zero of none is found.
function! FindLine(startLineNum, pattern)
  let lineNum = a:startLineNum
  let lastLineNum = line('$')
  let found = 0
  while (!found && lineNum <= lastLineNum)
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

" If line is the beginning of a class definition,
" returns the class name;
" otherwise returns 0 for false.
" If line contains "class" but isn't a proper start
" for a class definition, returns -1.
function! IsClassDefinition(line)
endf

function! LastToken(string)
  let tokens = split(a:string, ' ')
  return tokens[len(tokens) - 1]
endf

function! LogList(label, list)
  echomsg(a:label)
  for item in a:list
    echomsg('  ' . item)
  endfor
endf

" Returns the nth token in a string
" where the first token is 1.
function! NthToken(n, string)
  let tokens = split(a:string, ' ')
  return tokens[a:n - 1]
endf

function! Trim(string)
  return substitute(a:string, '^\s*\(.\{-}\)\s*$', '\1', '')
endf

" Converts a React component definition from a class to an arrow function.
function! ReactClassToFn()
  let line = getline('.') " gets entire current line
  let tokens = split(line, ' ')
  if tokens[0] != 'class'
    echomsg('must start with "class"')
    return
  endif
  if line !~ ' extends Component {$' &&
  \ line !~ ' extends React.Component {$'
    echomsg('must extend Component')
    return
  endif

  let startLineNum = line('.')
  let endLineNum = FindLine(startLineNum, '^}')
  if !endLineNum
    errormsg('end of class definition not found')
    return
  endif

  let className = tokens[1]

  let displayNameLineNum = FindLine(startLineNum, 'static displayName = ')
  if displayNameLineNum
    let line = getline(displayNameLineNum)
    let pattern = '\vstatic displayName \= ''(.+)'';'
    let result = matchlist(line, pattern)
    let displayName = result[1] " first capture group
  endif

  let propTypesLineNum = FindLine(startLineNum, 'static propTypes = {')
  if propTypesLineNum
    let propTypesLines = GetLinesTo(propTypesLineNum + 1, '};$')
    call remove(propTypesLines, len(propTypesLines) - 1)
    let propNames = []
    for line in propTypesLines
      call add(propNames, split(Trim(line), ':')[0])
    endfor
    let params = '{' . join(propNames, ', ') . '}'
  else
    let params = ''
  endif

  let renderLineNum = FindLine(startLineNum, ' render() {')
  if renderLineNum
    let renderLines = GetLinesTo(renderLineNum + 1, '}$')

    " Remove last line that closes the render method.
    call remove(renderLines, len(renderLines) - 1)

    " Remove any lines that destructure this.props since
    " all are destructured in the arrow function parameter list.
    let length = len(renderLines)
    let index = 0
    while index < length
      let line = renderLines[index]
      if line =~ '} = this.props;'
        call remove(renderLines, index)
        let length -= 1
      endif
      let index += 1
    endw

    " If the first render line is empty, remove it.
    if len(Trim(renderLines[0])) == 0
      call remove(renderLines, 0)
    endif
  else
    let renderLines = []
  endif

  let lines = ['const ' . className . ' = (' . params . ') => {']

  for line in renderLines
    call add(lines, line[2:])
  endfor
  call add(lines, '};')

  if exists('displayName')
    let lines += [
    \ '',
    \ className . ".displayName = '" . displayName . "';"
  \ ]
  endif

  if exists('propTypesLines')
    let lines += ['', className . '.propTypes = {']
    for line in propTypesLines
      call add(lines, '  ' . Trim(line))
    endfor
    let lines += ['};']
  endif

  call DeleteLines(startLineNum, endLineNum)
  call append(startLineNum - 1, lines)
endf

" Converts a React component definition from an arrow function to a class.
function! ReactFnToClass()
  let line = getline('.') " gets entire current line

  if line !~ ' =>'
    echomsg('not an arrow function')
    return
  endif

  let tokens = split(line, ' ')

  if (tokens[0] != 'const')
    echomsg('arrow function should be assigned using "const"')
    return
  endif

  if (tokens[2] != '=')
    echomsg('arrow function should be assigned to variable')
    return
  endif

  let tokenCount = len(tokens)
  let lastToken = tokens[tokenCount - 1]
  let prevToken = tokens[tokenCount - 2]
  let isAF = lastToken == '=>' ||
  \ (prevToken == '=>' && lastToken == '{')
  if (!isAF)
    echomsg('arrow function first line must end with => or => {')
    return
  endif

  let className = tokens[1]
  let lineNum = line('.')

  if lastToken == '{'
    " Find next line that only contains "};".
    if !FindLine(lineNum, '^\w*};\w*$')
      echomsg('ReactFnToClass: arrow function end not found')
      return -1
    endif
  else
    " Find next line that ends with ";".
    if !FindLine(lineNum, ';\w*$')
      echomsg('ReactFnToClass: arrow function end not found')
      return
    endif
  endif

  let lineNum = line('.')

  let hasBlock = line =~ '{$'
  if hasBlock
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

  let renderLines = GetLinesTo(lineNum + 1, ';$')

  call DeleteLines(lineNum,
  \ lineNum + len(renderLines) + (hasBlock ? 1 : 0))

  if !hasBlock
    " Remove semicolon from end of last line if exists.
    let index = len(renderLines) - 1
    let lastRenderLine = renderLines[index]
    if lastRenderLine =~ ';$'
      let renderLines[index] = lastRenderLine[0:-2]
    endif
  endif

  let displayNameLineNum = FindLine(lineNum, className . '.displayName =')
  if displayNameLineNum
    let displayName = LastToken(getline(displayNameLineNum))
    call DeleteLines(displayNameLineNum, displayNameLineNum)
    call DeleteLineIfBlank(displayNameLineNum - 1)
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
    call DeleteLineIfBlank(propTypesLineNum - 1)
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

  if !hasBlock
    call add(lines, '    return (')
  endif
  let indent = hasBlock ? '' : '  '

  for line in renderLines
    call add(lines, indent . '  ' . line)
  endfor

  if !hasBlock
    call add(lines, '    );')
  endif

  let lines += ['  }', '}']

  call append(lineNum - 1, lines)
endf

function! ReactToggleComponent()
  let lineNum = line('.')
  let colNum = col('.')

  let line = getline('.') " gets entire current line
  if line =~ '=>$' || line =~ '=> {$'
    call ReactFnToClass()
  elseif line =~ '^class ' || line =~ ' class '
    call ReactClassToFn()
  else
    echomsg('must be on first line of a React component')
  endif

  " Move cursor back to start.
  call cursor(lineNum, colNum)
endf

" If <leader>rt is not already mapped ...
if mapcheck("\<leader>rt", "N") == ""
  nnoremap <leader>rt :call ReactToggleComponent()<cr>
endif

