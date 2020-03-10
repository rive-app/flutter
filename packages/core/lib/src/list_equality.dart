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
  do {
    if (a.current != b.current) {
      return false;
    }
  } while (a.moveNext() && b.moveNext());

  return true;
}
