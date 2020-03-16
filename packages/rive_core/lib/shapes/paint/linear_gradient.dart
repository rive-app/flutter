import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/src/generated/shapes/paint/linear_gradient_base.dart';

class LinearGradient extends LinearGradientBase {
  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.worldTransform != 0) {
      // TODO: Update start/end.
    }
  }
  
}