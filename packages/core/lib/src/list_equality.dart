bool listEquals<T>(List<T> list1, List<T> list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  int length = list1.length;
  if (length != list2.length) return false;
  for (int i = 0; i < length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }
  return true;
}

bool iterableEquals<T>(Iterable<T> list1, Iterable<T> list2) {
  if (identical(list1, list2)) return true;
  if (list1 == null || list2 == null) return false;
  int length = list1.length;

  if (length != list2.length) return false;

  var a = list1.iterator;
  var b = list2.iterator;
  // Iterator starts at null current value, must be moved to first value.
  while (a.moveNext() && b.moveNext()) {
    if (a.current != b.current) {
      return false;
    }
  }

  return true;
}

/// Checks that all the retrieved values for an item are the same. If they're
/// the same, it returns the equal value, otherwise it'll return null.
K equalValue<T, K>(Iterable<T> items, K Function(T a) getValue) {
  if (items.isEmpty) {
    return null;
  }

  var iterator = items.iterator;
  // Move to first value.
  iterator.moveNext();
  K value = getValue(iterator.current);

  while (iterator.moveNext()) {
    if (value != getValue(iterator.current)) {
      return null;
    }
  }
  return value;
}
