import 'package:core/core.dart';

abstract class Interpolator {
  /// Usually mixed in/inherited from the core object that this is implemented
  /// on.
  Id get id;

  /// Convert a linear interpolation factor to an eased one.
  double transform(double value);

  bool equalParameters(Interpolator other);
}
