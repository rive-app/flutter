import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/fill.dart';

import '../../converters.dart';
import 'shape_paint.dart';

class FillBaseConverter extends ShapePaintConverter {
  FillBaseConverter(
    FillBase component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final fillRule = jsonData['fillRule'];

    final fillBase = component as FillBase;

    if (fillRule is String) {
      final ruleIndex = fillRule == 'evenodd' ? 1 : 0;
      fillBase.fillRule = ruleIndex;
    }
  }
}
