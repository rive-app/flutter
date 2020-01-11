library fractional;

var _minIndex = FractionalIndex.min();
var _maxIndex = FractionalIndex.max();

abstract class FractionallyIndexedList<T> extends Iterable<T> {
  final List<T> _values = List<T>();
  FractionalIndex orderOf(T value);

  int get length => _values.length;
  void setOrderOf(T value, FractionalIndex order);

  operator [](int i) => _values[i];

  int _compareIndex(T a, T b) {
    return orderOf(a).compareTo(orderOf(b));
  }

  void sort() => _values.sort(_compareIndex);

  void add(T item) {
    assert(!contains(item));
    _values.add(item);
  }

  bool remove(T item) => _values.remove(item);

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
    assert(before != null && after != null);
    setOrderOf(item, FractionalIndex.between(orderOf(before), orderOf(after)));
  }

  @override
  Iterator<T> get iterator => _values.iterator;

  @override
  bool contains(Object element) => _values.contains(element);
}

class FractionalIndex {
  final int numerator;
  final int denominator;

  const FractionalIndex(this.numerator, this.denominator)
      : assert(numerator < denominator);

  const FractionalIndex.min()
      : this.numerator = 0,
        this.denominator = 1;
  const FractionalIndex.max()
      : this.numerator = 1,
        this.denominator = 1;

  int compareTo(FractionalIndex other) {
    return numerator * other.denominator - denominator * other.numerator;
  }

  FractionalIndex combine(FractionalIndex other) {
    return FractionalIndex(
        numerator + other.numerator, denominator + other.denominator);
  }

  static FractionalIndex between(FractionalIndex a, FractionalIndex b) {
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

  @override
  String toString() {
    return "$numerator/$denominator";
  }
}
