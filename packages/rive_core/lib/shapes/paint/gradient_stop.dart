import 'dart:ui' as ui;

import 'package:rive_core/container_component.dart';
import 'package:rive_core/src/generated/shapes/paint/gradient_stop_base.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';

class GradientStop extends GradientStopBase {
  LinearGradient _gradient;
  ui.Color get color => ui.Color(colorValue);
  set color(ui.Color c) {
    colorValue = c.value;
  }

  @override
  void positionChanged(double from, double to) {
    super.positionChanged(from, to);
    _gradient?.markStopsDirty();
  }

  @override
  void colorValueChanged(int from, int to) {
    super.colorValueChanged(from, to);
    _gradient?.markGradientDirty();
  }

  @override
  void update(int dirt) {
    // TODO: implement update
  }

  @override
  void parentChanged(ContainerComponent from, ContainerComponent to) {
    super.parentChanged(from, to);
    if (parent is LinearGradient) {
      _gradient = parent as LinearGradient;
    } else {
      // Important to clear old references so they can be garbage collected.
      _gradient = null;
    }
  }
}
