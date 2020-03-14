/// Extension methods to help filtering in the inspector.
extension InspectorFilters<T> on Iterable<T> {
  /// Checks if all the items in the iterable have the same value for [test].
  bool allSame<K>(K Function(T) test) {
    if (isEmpty) {
      return true;
    }

    K value = test(first);
    for (final item in skip(1)) {
      if (test(item) != value) {
        return false;
      }
    }
    return true;
  }

  /// Swap rows and columns. Requires that each test returns an iterable of the
  /// same length.
  List<List<K>> transpose<K>(Iterable<K> Function(T) test) {
    // requires items to be of the same length.
    Iterable<K> firstList = test(first);
    List<List<K>> lists = List<List<K>>(firstList.length);
    int i = 0;

    int l = length;
    for (final item in firstList) {
      var list = List<K>(l);
      lists[i++] = list;
      list[0] = item;
    }

    int idx = 1;
    for (final item in skip(1)) {
      var list = test(item);
      int i = 0;
      for (final item in list) {
        lists[i++][idx] = item;
      }
      idx++;
    }
    return lists;
  }
}
