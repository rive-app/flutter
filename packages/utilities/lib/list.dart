// List extensions
extension ListExtension on List {
  /// given a list, return the singular, plural or nill form.
  String pluralize(String singular, String plural, [String nill]) {
    if (length == 0) {
      return nill ?? plural;
    } else if (length == 1) {
      return singular;
    } else {
      return plural;
    }
  }
}
