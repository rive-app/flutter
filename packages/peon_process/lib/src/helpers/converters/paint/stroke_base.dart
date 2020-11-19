import 'package:flutter/material.dart';
import 'package:peon_process/converters.dart';
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
      stroke.join = _joinFromString(join);
    }

    if (transformAffectsStroke is bool) {
      stroke.transformAffectsStroke = transformAffectsStroke;
    }
  }

  // Same index as the StrokeCap values in dart:ui
  int _capFromString(String capName) {
    switch (capName) {
      case 'round':
        return StrokeCap.round.index;
      case 'square':
        return StrokeCap.square.index;
      case 'butt':
      default:
        return StrokeCap.butt.index;
    }
  }

  // Same index as the StrokeJoin values in dart:ui
  int _joinFromString(String joinName) {
    switch (joinName) {
      case 'round':
        return StrokeJoin.round.index;
      case 'bevel':
        return StrokeJoin.bevel.index;
      case 'miter':
      default:
        return StrokeJoin.miter.index;
    }
  }
}
