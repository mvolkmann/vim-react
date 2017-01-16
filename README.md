# vim-react-class-fn-toggle

This plugin provides one function, `ReactToggleComponent`, that toggles
the implemenation of a React component between class-based and functional.
This function is mapped to <leader>rt unless that key is already mapped.
Just place the cursor on the first line of an existing React component
definition and run the function to toggle it.

The plugin makes certain assumptions about the code
and the result to be produced.
If you are unhappy with the results, please open an issue and
I will consider making this more configurable.
