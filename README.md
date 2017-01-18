# vim-react

This plugin provides several functions.

### `ReactToggleComponent`
This function toggles the implementation of a React component
between class-based and functional.
It is mapped to `<leader>rt` unless that key is already mapped.
Just place the cursor on the first line of an existing
React component definition and run the function to toggle it.

Here is an example of a functional React component.
````
const Foo = ({bar, baz}) => {
  return (
    <div>
      <div>bar = {bar}</div>
      <div>baz = {baz}</div>
    </div>
  );
};

Foo.displayName = 'Foo';

Foo.propTypes = {
  bar: number,
  baz: string
};
````

Here is an example of an equivalent class-based React component.
````
class Foo extends Component {
  static displayName = 'Foo';

  static propTypes = {
    bar: number,
    baz: string
  };

  render() {
    const {bar, baz} = this.props;
    return (
      <div>
        <div>bar = {bar}</div>
        <div>baz = {baz}</div>
      </div>
    );
  }
}
````

`ReactToggleComponent` will convert either of these forms to the other.

### JSXCommentAdd
This function adds a JSX comment `{/* ... */}`
around the lines selected in visual mode.
It is mapped to `<leader>jc` in visual mode
unless that key is already mapped.

### JSXCommentRemove
This function removes the JSX comment `{/* ... */}`
surrounding the current line in normal mode.
It is mapped to `<leader>jc` in normal mode
unless that key is already mapped.

These functions makes certain assumptions about the code
and the result to be produced.
If you are unhappy with the results, please open an issue and
I will consider making this more configurable.
