" This plugin defines two commands.
" The first converts a React stateless functional component
" to a class-based component.
" The second converts a React class-based component
" to a stateless functional component.

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

  let propNames = 'props go here'
  let propTypes = 'prop types go here'

  let lines = [
  \ 'const ' . className . ' = ({' . propNames . '}) =>',
  \ '  return (',
  \ '  );',
  \ '};'
  \ ]

  if exists('displayName')
    let lines += [
    \ '',
    \ className . ".displayName = '" . displayName . "';"
  \ ]
  endif

  if exists('propTypes')
    let lines += [
    \ '',
    \ className . '.propTypes = {',
    \ '};'
    \ ]
  endif

  call DeleteLines(startLineNum, endLineNum)
  call append(startLineNum - 1, lines)
endf

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
  let line = getline('.') " gets entire current line
  if line =~ '=>$' || line =~ '=> {$'
    call ReactFnToClass()
  elseif line =~ '^class ' || line =~ ' class '
    call ReactClassToFn()
  else
    echomsg('must be on first line of a React component')
  endif
endf

" If <leader>rt is not already mapped ...
if mapcheck("\<leader>rt", "N") == ""
  nnoremap <leader>rt :call ReactToggleComponent()<cr>
endif

