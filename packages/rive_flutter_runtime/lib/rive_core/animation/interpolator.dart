import 'package:rive/src/core/core.dart';
abstract class Interpolator {
  int get id;
  double transform(double value);
  bool equalParameters(Interpolator other);
}
