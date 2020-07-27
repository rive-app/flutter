import 'package:peon_process/src/helpers/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/stroke.dart';

class StrokeBaseConverter extends ShapePaintConverter {
  StrokeBaseConverter(
    StrokeBase component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);

    final width = jsonData['width'];
    final cap = jsonData['cap'];
    final join = jsonData['join'];
    final transformAffectsStroke = jsonData['transformAffectsStroke'];
    final trim = jsonData['trim'];
    final trimStart = jsonData['trimStart'];
    final trimEnd = jsonData['trimEnd'];
    final trimOffset = jsonData['trimOffset'];

    final stroke = component as StrokeBase;

    if (width is num) {
      stroke.thickness = width.toDouble();
    }

    if (cap is String) {
      stroke.cap = _capFromString(cap);
    }

    if (join is String) {
      stroke.cap = _joinFromString(join);
    }

    if (transformAffectsStroke is bool) {
      stroke.transformAffectsStroke = transformAffectsStroke;
    }
  }

  // Same index as the StrokeCap values in dart:ui
  int _capFromString(String capName) {
    switch (capName) {
      case 'butt':
        return 0;
      case 'round':
        return 1;
      case 'square':
        return 2;
      default:
        return 0;
    }
  }

  // Same index as the StrokeJoin values in dart:ui
  int _joinFromString(String joinName) {
    switch (joinName) {
      case 'miter':
        return 0;
      case 'round':
        return 1;
      case 'bevel':
        return 2;
      default:
        return 0;
    }
  }
}
