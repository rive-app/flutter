// import 'package:core/core.dart';
import 'package:peon_process/converters.dart';
// import 'package:rive_core/animation/keyframe_draw_order.dart';
// import 'package:rive_core/animation/keyframe_draw_order_value.dart';
// import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
// import 'package:rive_core/drawable.dart';

class KeyFrameDrawOrderConverter extends KeyFrameConverter {
  const KeyFrameDrawOrderConverter(this.fileComponents, Map value,
      int interpolatorType, List interpolatorCurve)
      : super(value, interpolatorType, interpolatorCurve);

  final Map<String, Component> fileComponents;

  @override
  void convertKey(Component component, LinearAnimation animation, int frame) {
    // TODO: decide what to do with this with the new draw order system...
    // Draw Order is keyed to the Artboard.
    // final artboard = component.artboard;
    // final key = generateKey<KeyFrameDrawOrder>(
    //     artboard, animation, frame, DrawableBase.drawOrderPropertyKey);

    // final drawOrderValues = value as Map<String, Object>;

    // for (final componentId in drawOrderValues.keys) {
    //   final drawOrderComponent = fileComponents[componentId];
    //   final drawOrder = (drawOrderValues[componentId] as num).toInt();
    //   final drawOrderValue = KeyFrameDrawOrderValue()
    //     ..drawableId = drawOrderComponent.id
    //     ..value = FractionalIndex(drawOrder, drawOrder + 1);
    //   key.internalAddValue(drawOrderValue);
    //   key.interpolation = KeyFrameInterpolation.hold;
    // }
  }
}
