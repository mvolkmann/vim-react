# vim-react-class-fn-toggle

This plugin provides several functions.

## `ReactToggleComponent`
This function toggles the implementation of a React component
between class-based and functional.
It is mapped to `<leader>rt` unless that key is already mapped.
Just place the cursor on the first line of an existing
React component definition and run the function to toggle it.

## JSXCommentAdd
This function adds a JSX comment {/* ... */}
around the lines selected in visual mode.
It is mapped to `<leader>jc` in visual mode
unless that key is already mapped.

## JSXCommentRemove
This function removes a JSX comment {/* ... */}
surround the current line in normal mode.
It is mapped to `<leader>jc` in normal mode
unless that key is already mapped.

These functions makes certain assumptions about the code
and the result to be produced.
If you are unhappy with the results, please open an issue and
I will consider making this more configurable.
