import React, {Component} from 'react';

const {number, string} = React.PropTypes;

// before
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
// after

// before
const Foo = ({bar, baz}) =>
  <div>
    <div>bar = {bar}</div>
    <div>baz = {baz}</div>
  </div>;
// after

// before
const Foo = ({bar, baz}) => {
  return (
    <div>
      <div>bar = {bar}</div>
      <div>baz = {baz}</div>
    </div>
  );
};
// after

// before
Foo.displayName = 'FooBar';
Foo.propTypes = {
  bar: number,
  baz: string
};
// after

export default Foo1;
