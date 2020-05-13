import 'package:core/core.dart';
import 'package:flutter/foundation.dart';

abstract class Interpolator {
  // -> editor-only
  /// Notifies when any of the interpolator properties change. We do this as a
  /// general way to know when a core property key of the notifier has changed
  /// (this way you don't need to know the concrete propertyKeys for each
  /// interpolator).
  ChangeNotifier get propertiesChanged;
  // <- editor-only

  /// Usually mixed in/inherited from the core object that this is implemented
  /// on.
  Id get id;

  /// Convert a linear interpolation factor to an eased one.
  double transform(double value);

  bool equalParameters(Interpolator other);
}
