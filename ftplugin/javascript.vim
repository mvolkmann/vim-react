let sample = "const Foo = ({\nbar,\nbaz\n}) =>"
"let pattern = '\s*const (\w+) = \((\_.+)\) \=>( =>)?'
let pattern = '\v\s*const (\w+) \= \((\_.+)\) \=\>( {})?'
let result = matchlist(sample, pattern)
let className = result[1]
"echo 'className = ' . className
let props = result[2]
"echo 'props = ' . props
"echo 'foo' =~# 'f'
"echo matchlist('foo bar baz', '\v\s*(\w+) (\w+) (\w+)')

" This file depends on many functions defined in plugins/utilities.vim.

function! JSXPropJoin()
  " If current line doesn't start with <, error.
  " Find next >
  " Join all the lines in between.
  " Delete the previous lines.
  " Append the new line.
  echo 'not implemented yet'
endf

function! JSXPropSplit()
  " If current line doesn't start with <, error.
  " Get a string from < to >.
  " Split the string using a regex.
  " Delete the current line.
  " Append the new lines.
  echo 'not implemented yet'
endf

function! JSXCommentAdd()
  " Get first and last line number selected in visual mode.
  let firstLineNum = line("'<")
  let lastLineNum = line("'>")

  let column = match(getline(firstLineNum), '\w')
  let indent = repeat(' ', column - 1)

  call append(lastLineNum, indent . '*/}')
  call append(firstLineNum - 1, indent . '{/*')
endf

function! JSXCommentRemove()
  let lineNum = line('.')
  let startLineNum = vru#FindPreviousLine(lineNum, '{/\*')
  if startLineNum == 0
    echo 'no JSX comment found'
    return
  endif

  let endLineNum = vru#FindNextLine(lineNum, '*/}')
  call vru#DeleteLine(endLineNum)
  call vru#DeleteLine(startLineNum)
endf

" Converts a React component definition from a class to an arrow function.
function! ReactClassToFn()
  let line = getline('.') " gets entire current line
  let tokens = split(line, ' ')
  if tokens[0] !=# 'class'
    echo 'must start with "class"'
    return
  endif
  if line !~# ' extends Component {$' &&
  \ line !~# ' extends React.Component {$'
    echo 'must extend Component'
    return
  endif

  let startLineNum = line('.')
  let endLineNum = vru#FindNextLine(startLineNum, '^}')
  if !endLineNum
    echo 'end of class definition not found'
    return
  endif

  let className = tokens[1]

  let displayNameLineNum = vru#FindNextLine(startLineNum, 'static displayName = ')
  if displayNameLineNum
    let line = getline(displayNameLineNum)
    let pattern = '\vstatic displayName \= ''(.+)'';'
    let result = matchlist(line, pattern)
    let displayName = result[1] " first capture group
  endif

  let propTypesLineNum = vru#FindNextLine(startLineNum, 'static propTypes = {$')
  let propTypesInsideClass = propTypesLineNum ? 1 : 0
  if !propTypesLineNum
    let propTypesLineNum = vru#FindNextLine(startLineNum, className . '.propTypes = {$')
  endif
  if propTypesLineNum
    let propTypesLines = vru#GetLinesTo(propTypesLineNum + 1, '};$')
    call vru#PopList(propTypesLines)
    let propNames = []
    for line in propTypesLines
      call add(propNames, split(vru#Trim(line), ':')[0])
    endfor
    let params = '{' . join(propNames, ', ') . '}'
  else
    let params = ''
  endif

  let renderLineNum = vru#FindNextLine(startLineNum, ' render() {')
  if renderLineNum
    let renderLines = vru#GetLinesTo(renderLineNum + 1, '^\s*}$')

    " Remove last line that closes the render method.
    call vru#PopList(renderLines)

    " Remove any lines that destructure this.props since
    " all are destructured in the arrow function parameter list.
    let length = len(renderLines)
    let index = 0
    while index < length
      let line = renderLines[index]
      if line =~# '} = this.props;'
        call remove(renderLines, index)
        let length -= 1
      endif
      let index += 1
    endw

    " If the first render line is empty, remove it.
    if len(vru#Trim(renderLines[0])) == 0
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

  if exists('propTypesLines') && propTypesInsideClass
    let lines += ['', className . '.propTypes = {']
    for line in propTypesLines
      call add(lines, '  ' . vru#Trim(line))
    endfor
    let lines += ['};']
  endif

  call vru#DeleteLines(startLineNum, endLineNum)
  call append(startLineNum - 1, lines)
endf

" Converts a React component definition from an arrow function to a class.
function! ReactFnToClass()
  let line = getline('.') " gets entire current line
  let tokens = split(line, ' ')

  if (tokens[0] !=# 'const')
    echo 'arrow function should be assigned using "const"'
    return
  endif

  if (tokens[2] !=# '=')
    echo 'arrow function should be assigned to variable'
    return
  endif

  let lineNum = line('.')
  const arrowLineNum = vru#FindNextLine(lineNum, '=>')
  echo 'arrowLineNum = '. arrowLineNum
  return

  if line !~# ' =>'
    echo 'not an arrow function'
    return
  endif

  let tokenCount = len(tokens)
  let lastToken = tokens[tokenCount - 1]
  let prevToken = tokens[tokenCount - 2]
  let isAF = lastToken ==# '=>' ||
  \ (prevToken ==# '=>' && lastToken ==# '{')
  if (!isAF)
    echo 'arrow function first line must end with => or => {'
    return
  endif

  let className = tokens[1]

  let hasBlock = line =~# '{$'
  if hasBlock
    " Find next line that only contains "};".
    if !vru#FindNextLine(lineNum, '^\w*};\w*$')
      echo 'arrow function end not found'
      return
    endif
  else
    " Find next line that ends with ";".
    if !vru#FindNextLine(lineNum, ';\w*$')
      echo 'arrow function end not found'
      return
    endif
  endif

  let renderLines = vru#GetLinesTo(lineNum + 1, '^};$')
  call vru#PopList(renderLines)

  call vru#DeleteLines(lineNum,
  \ lineNum + len(renderLines) + (hasBlock ? 1 : 0))

  if !hasBlock
    " Remove semicolon from end of last line if exists.
    let index = len(renderLines) - 1
    let lastRenderLine = renderLines[index]
    if lastRenderLine =~# ';$'
      let renderLines[index] = lastRenderLine[0:-2]
    endif
  endif

  let displayNameLineNum = vru#FindNextLine(lineNum, className . '.displayName =')
  if displayNameLineNum
    let displayName = vru#LastToken(getline(displayNameLineNum))
    call vru#DeleteLine(displayNameLineNum)
    call vru#DeleteLineIfBlank(displayNameLineNum - 1)
  endif

  let propTypesLineNum = vru#FindNextLine(lineNum, className . '.propTypes =')
  if propTypesLineNum
    let propTypes = vru#GetLinesTo(propTypesLineNum + 1, '.*};')
    let propNames = []
    for line in propTypes
      let propName = vru#Trim(split(line, ':')[0])
      if propName !=# '};'
        call add(propNames, propName)
      endif
    endfor
    call vru#DeleteLines(propTypesLineNum, propTypesLineNum + len(propTypes))
    call vru#DeleteLineIfBlank(propTypesLineNum - 1)
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
    let output = len(line) ? indent . '  ' . line : line
    call add(lines, output)
  endfor

  if !hasBlock
    call add(lines, '    );')
  endif

  let lines += ['  }', '}']

  call append(lineNum - 1, lines)
endf

function! OnArrowFunction(startLineNum)
  let lineNum = a:startLineNum
  let arrowLineNum = vru#FindNextLine(lineNum, '=>')
  if !arrowLineNum
    return []
  endif

  let result = ''
  while lineNum <= arrowLineNum
    let result = result . ' ' . vru#Trim(getline(lineNum))
    let lineNum += 1
  endw
  echo 'result = ' . result
  let pattern = '\v\s*const (\w+) \= \((\_.+)\) \=\>( {})?'
  let matches = matchlist(result, pattern)
  return matches
endf

function! ReactToggleComponent()
  let lineNum = line('.')
  let colNum = col('.')

  let line = getline('.') " gets entire current line
  "if line =~# '=>$' || line =~# '=> {$'
  let matches = OnArrowFunction(lineNum)
  call vru#LogList('matches', matches)
  if len(matches)
    call ReactFnToClass()
  elseif line =~# '^class ' || line =~# ' class '
    call ReactClassToFn()
  else
    echo 'must be on first line of a React component'
  endif

  " Move cursor back to start.
  call cursor(lineNum, colNum)
endf

" <c-u> removes the automatic range specification
" when command mode is entered from visual mode,
" changing the command line from :'<'> to just :

" If <leader>jc for "JSX Comment" is not already mapped ...
if mapcheck('\<leader>jc', 'N') ==# ''
  nnoremap <leader>jc :call JSXCommentRemove()<cr>
  vnoremap <leader>jc :<c-u>call JSXCommentAdd()<cr>
endif

" If <leader>js for "JSX Split" is not already mapped ...
if mapcheck('\<leader>js', 'N') ==# ''
  nnoremap <leader>js :call JSXPropSplit()<cr>
endif

" If <leader>rt for "React Toggle" is not already mapped ...
if mapcheck('\<leader>rt', 'N') ==# ''
  nnoremap <leader>rt :call ReactToggleComponent()<cr>
endif
