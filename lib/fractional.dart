library fractional;

import 'dart:collection';

const _minIndex = FractionalIndex.min();
const _maxIndex = FractionalIndex.max();

abstract class FractionallyIndexedList<T> extends ListBase<T> {
  final List<T> _values;
  FractionalIndex orderOf(T value);
  List<T> get values => _values;

  @override
  int get length => _values.length;

  @override
  set length(int value) => _values.length = value;

  @override
  T operator [](int index) => _values[index];

  @override
  void operator []=(int index, T value) => _values[index] = value;

  FractionallyIndexedList({List<T> values}) : _values = values ?? <T>[] {
    if (_values.isEmpty) {
      return;
    }
    int mid = _values.length ~/ 2;
    var midIndex = const FractionalIndex(1, 2);
    setOrderOf(_values[mid], midIndex);

    var lastIndex = midIndex;
    for (int i = mid + 1; i < _values.length; i++) {
      var index = FractionalIndex.between(lastIndex, _maxIndex);
      setOrderOf(_values[i], index);
      lastIndex = index;
    }

    lastIndex = midIndex;
    for (int i = mid - 1; i >= 0; i--) {
      var index = FractionalIndex.between(_minIndex, lastIndex);
      setOrderOf(_values[i], index);
      lastIndex = index;
    }
  }

  void setOrderOf(T value, FractionalIndex order);

  int _compareIndex(T a, T b) {
    return orderOf(a).compareTo(orderOf(b));
  }

  void sortFractional() => _values.sort(_compareIndex);

  @override
  void add(T item) {
    assert(!contains(item));
    _values.add(item);
  }

  @override
  bool remove(Object element) => _values.remove(element);

  void append(T item) {
    assert(!contains(item));
    var previousIndex = _values.isEmpty ? _minIndex : orderOf(_values.last);
    setOrderOf(item, FractionalIndex.between(previousIndex, _maxIndex));
    _values.add(item);
  }

  void prepend(T item) {
    assert(!contains(item));
    var firstIndex = _values.isEmpty ? _maxIndex : orderOf(_values.first);
    setOrderOf(item, FractionalIndex.between(_minIndex, firstIndex));
    _values.add(item);
  }

  void moveToEnd(T item) {
    var previousIndex = _values.isEmpty ? _minIndex : orderOf(_values.last);
    setOrderOf(item, FractionalIndex.between(previousIndex, _maxIndex));
  }

  void moveToStart(T item) {
    var firstIndex = _values.isEmpty ? _maxIndex : orderOf(_values.first);
    setOrderOf(item, FractionalIndex.between(_minIndex, firstIndex));
  }

  void move(T item, {T before, T after}) {
    setOrderOf(
        item,
        FractionalIndex.between(before != null ? orderOf(before) : _minIndex,
            after != null ? orderOf(after) : _maxIndex));
  }
}

class FractionalIndex {
  final int numerator;
  final int denominator;

  const FractionalIndex(this.numerator, this.denominator)
      : assert(numerator < denominator);

  const FractionalIndex.min()
      : numerator = 0,
        denominator = 1;
  const FractionalIndex.max()
      : numerator = 1,
        denominator = 1;

  int compareTo(FractionalIndex other) {
    return numerator * other.denominator - denominator * other.numerator;
  }

  FractionalIndex combine(FractionalIndex other) {
    return FractionalIndex(
        numerator + other.numerator, denominator + other.denominator);
  }

  factory FractionalIndex.between(FractionalIndex a, FractionalIndex b) {
    return FractionalIndex(
            a.numerator + b.numerator, a.denominator + b.denominator)
        .reduce();
  }

  FractionalIndex reduce() {
    int x = numerator, y = denominator;
    while (y != 0) {
      int t = y;
      y = x % y;
      x = t;
    }
    return FractionalIndex(numerator ~/ x, denominator ~/ x);
  }

  bool operator <(FractionalIndex other) {
    return compareTo(other) < 0;
  }

  bool operator >(FractionalIndex other) {
    return compareTo(other) > 0;
  }

  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    final FractionalIndex typedOther = other;
    return numerator == typedOther.numerator &&
        denominator == typedOther.denominator;
  }

  @override
  String toString() {
    return '$numerator/$denominator';
  }
}
