/// Extension methods to standardize oftenly repeated patterns for iterables.
extension MoreIterating<T> on Iterable<T> {

  // Map but with loose type restrictions such that it can then be filtered on
  // that type.
  Iterable<K> mapWhereType<K>(dynamic Function(T) mapping) {
    return map<dynamic>(mapping).whereType<K>();
  }
}
