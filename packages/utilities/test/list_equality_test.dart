import 'package:fractional/fractional.dart';
import 'package:test/test.dart';
import 'package:utilities/list_equality.dart';

void main() {
  test('list equality returns true for items with the same content', () {
    final listA = ['a', 'b', 'c', 'd'];
    final listB = ['a', 'b', 'c', 'd'];
    expect(listEquals(listA, listB), true);
    expect(iterableEquals(listA, listB), true);
  });

  test('list equality returns false for items with different content', () {
    final listA = ['F', 'b', 'c', 'd'];
    final listB = ['a', 'b', 'c', 'd'];
    expect(listEquals(listA, listB), false);
    expect(iterableEquals(listA, listB), false);
  });

  test('list equality returns false for lists with different lengths', () {
    final listA = ['a', 'b', 'c', 'd', 'e'];
    final listB = ['a', 'b', 'c', 'd'];
    expect(listEquals(listA, listB), false);
    expect(iterableEquals(listA, listB), false);
  });

  test('list equality works with custom types', () {
    final listA = [
      const FractionalIndex(1, 2),
      const FractionalIndex(3, 4),
      const FractionalIndex(5, 8),
      const FractionalIndex(1, 5),
      const FractionalIndex(9, 12),
    ];
    final listB = [
      const FractionalIndex(1, 2),
      const FractionalIndex(3, 4),
      const FractionalIndex(5, 8),
      const FractionalIndex(1, 5),
      const FractionalIndex(9, 12),
    ];

    final listC = [
      const FractionalIndex(1, 2),
      const FractionalIndex(3, 4),
      const FractionalIndex(5, 19),
      const FractionalIndex(1, 5),
      const FractionalIndex(9, 12),
    ];
    expect(listEquals(listA, listB), true);
    expect(listEquals(listA, listC), false);
    expect(iterableEquals(listA, listB), true);
    expect(iterableEquals(listA, listC), false);
  });

  test('equal value returns the expected value', () {
    final listA = [
      const FractionalIndex(1, 12),
      const FractionalIndex(1, 4),
      const FractionalIndex(1, 12),
      const FractionalIndex(1, 5),
      const FractionalIndex(1, 12),
    ];

    // All numerators are the same, expect the equalValue to be 1.
    expect(
        equalValue<FractionalIndex, int>(listA, (index) => index.numerator), 1);

    // Not all denominators are the same, expect the equalValue to be null.
    expect(
        equalValue<FractionalIndex, int>(listA, (index) => index.denominator),
        null);
  });
}
