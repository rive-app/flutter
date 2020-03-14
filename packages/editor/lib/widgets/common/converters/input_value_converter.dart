/// An abstraction of a value converter which can be used with text input fields
/// that accept value converters to display a more legible/easier to understand
/// version of the raw values. For example, an AngleConverter could show degrees
/// instead of the backing radian value.
abstract class InputValueConverter<T> {
  /// Returns the displayed version of the [value]. This can be an abbreviation
  /// (for example rounded to the nearest hundredths) or something more legible
  /// than the full edit value. By default this'll simply show the same value as
  /// the editing one.
  String toDisplayValue(T value) => toEditingValue(value);

  /// The precise version of the display value such that the user can make fine
  /// modifications to it via text manipulation. For example, if you chose to
  /// display a number abbreviated to the tenths in the display value, you may
  /// want to let the user edit up to hundredths when it's focused and being
  /// edited.
  String toEditingValue(T value);

  /// Convert the user provided string input value to an actual value of the
  /// correct type.
  T fromEditingValue(String value);
}
