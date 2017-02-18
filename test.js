import React, {Component, PropTypes as t} from 'react';

// before
class Foo1 extends Component {
  static displayName = 'Foo1';

  static propTypes = {
    bar: t.number,
    baz: t.string
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
const Foo2 = ({bar, baz}) => {
  return (
    <div>
      <div>bar = {bar}</div>
      <div>baz = {baz}</div>
    </div>
  );
};

Foo2.displayName = 'FooBar';
Foo2.propTypes = {
  bar: t.number,
  baz: t.string
};
// after

// before
const Foo3 = ({
  bar,
  baz
}) =>
  <div>
    <div>bar = {bar}</div>
    <div>baz = {baz}</div>
  </div>;

Foo3.displayName = 'FooBar';
Foo3.propTypes = {
  bar: t.number,
  baz: t.string
};
// after

export default Foo1, Foo2, Foo3;
