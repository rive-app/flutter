import 'package:flutter_test/flutter_test.dart';
import 'package:fractional/fractional.dart';

class Component {
  FractionalIndex hierarchyOrder;
  final String name;

  Component(this.name);
}

class ComponentChildren extends FractionallyIndexedList<Component> {
  @override
  FractionalIndex orderOf(Component value) {
    return value.hierarchyOrder;
  }

  @override
  void setOrderOf(Component value, FractionalIndex order) {
    value.hierarchyOrder = order;
  }
}

void main() {
  test('can make a FractionallyIndexedList', () {
    var children = ComponentChildren();

    var c = Component("Test");
    children.append(c);
    expect(c.hierarchyOrder.numerator, 1);
    expect(c.hierarchyOrder.denominator, 2);
    expect(children.length, 1);
  });

  test('items are in the expected order', () {
    var children = ComponentChildren();

    children.append(Component("First"));
    children.append(Component("Second"));
    children.append(Component("Third"));

    expect(children.length, 3);

    expect(children[0].hierarchyOrder.numerator, 1);
    expect(children[0].hierarchyOrder.denominator, 2);

    expect(children[1].hierarchyOrder.numerator, 2);
    expect(children[1].hierarchyOrder.denominator, 3);

    expect(children[2].hierarchyOrder.numerator, 3);
    expect(children[2].hierarchyOrder.denominator, 4);

    children.sort();

    expect(children[0].name, "First");
    expect(children[1].name, "Second");
    expect(children[2].name, "Third");

    // Let's move First between Second and Third.
    // children[0].hierarchyOrder = FractionalIndex.between(
    //     children[1].hierarchyOrder, children[2].hierarchyOrder);
    children.move(children[0], after: children[1], before: children[2]);
    children.sort();

    expect(children[0].name, "Second");
    expect(children[1].name, "First");
    expect(children[2].name, "Third");
  });

  test('fractional indices can compare', () {
    expect(FractionalIndex(2, 7) < FractionalIndex(5, 8), true);

    expect(FractionalIndex(1, 2) < FractionalIndex(4, 7), true);
  });

  test('between values are correct', () {
    expect(
        FractionalIndex.between(FractionalIndex(2, 7), FractionalIndex(5, 8)) <
            FractionalIndex(5, 8),
        true);
    expect(
        FractionalIndex.between(FractionalIndex(2, 7), FractionalIndex(5, 8)) >
            FractionalIndex(2, 7),
        true);
    expect(
        FractionalIndex.between(FractionalIndex(1, 3), FractionalIndex(5, 8)) <
            FractionalIndex(5, 8),
        true);
    expect(
        FractionalIndex.between(FractionalIndex(1, 3), FractionalIndex(5, 8)) >
            FractionalIndex(1, 3),
        true);
  });

  // test('adds one to input values', () {
  //   var a = FractionalIndex(1, 4);
  //   var b = FractionalIndex(2, 5);

  //   var list = [
  //     FractionalIndex(1, 3),
  //     FractionalIndex(2, 5),
  //     FractionalIndex(1, 4),
  //   ];
  //   list.sort();
  //   print("SORTED ${list}");

  //   {
  //     double value = 0.5;
  //     for (int i = 0; i < 5000; i++) {
  //       value /= 0.5;
  //       if (value == double.infinity) {
  //         print("FAILED AT $i");
  //         break;
  //       }
  //     }
  //     print("VALUE IS $value");
  //   }

  //   {
  //     var lower = FractionalIndex(1, 3);
  //     var value = FractionalIndex(2, 3);

  //     var values = [value];
  //     var valuesR = [value];
  //     for (int i = 0; i < 20; i++) {
  //       value = value.combine(lower);
  //       values.insert(0, value);
  //       valuesR.insert(0, value.reduce());
  //     }
  //     // [11/32, 10/29, 9/26, 8/23, 7/20, 6/17, 5/14, 4/11, 3/8, 2/5, 1/2]
  //     // [11/32, 10/29, 9/26, 8/23, 7/20, 6/17, 5/14, 4/11, 3/8, 2/5, 1/2]
  //     print("$values");
  //     values.sort();
  //     print("$values");
  //     print("$valuesR");
  //     valuesR.sort();
  //     print("$valuesR");
  //   }
  // });
}
