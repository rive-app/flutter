// String extensions
extension StringExtensions on String {
  /// Capitalize the first letter of a string
  String get capsFirst {
    assert(length > 0);
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
