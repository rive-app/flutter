import 'package:rive/src/core/core.dart';
import 'package:flutter/foundation.dart';

abstract class Interpolator {
  int get id;
  double transform(double value);
  bool equalParameters(Interpolator other);
}
