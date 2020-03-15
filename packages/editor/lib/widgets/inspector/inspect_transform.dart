import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_editor/widgets/common/converters/rotation_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/scale_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';

/// Returns the inspector for Artboard selections.
class TransformInspectorBuilder extends InspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(NodeBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) => PropertyDual(
            name: 'Position',
            objects: inspecting.components,
            propertyKeyA: NodeBase.xPropertyKey,
            propertyKeyB: NodeBase.yPropertyKey,
            labelA: 'X',
            labelB: 'Y',
            converter: TranslationValueConverter.instance,
          ),
      (context) => PropertyDual(
            name: 'Scale',
            linkable: true,
            objects: inspecting.components,
            propertyKeyA: NodeBase.scaleXPropertyKey,
            propertyKeyB: NodeBase.scaleYPropertyKey,
            labelA: 'X',
            labelB: 'Y',
            converter: ScaleValueConverter.instance,
          ),
      (context) => PropertySingle(
            name: 'Rotate',
            objects: inspecting.components,
            propertyKey: NodeBase.rotationPropertyKey,
            converter: RotationValueConverter.instance,
          ),

      // If the inspection set has all parametric paths, show the width/height
      // options for the paths too.
      //
      // N.B. this only works if the path is in the selection (you'll need to
      // expand the shape in the hierarchy and select the path within it). Later
      // we'll add the concept of width/height directly to a shape but it may
      // not be a core property, so we'll need some PropertyDual that works with
      // change callbacks and not propertyKeys
      if (inspecting.intersectingCoreTypes.contains(ParametricPathBase.typeKey))
        (context) => PropertyDual(
              name: 'Size',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: ParametricPathBase.widthPropertyKey,
              propertyKeyB: ParametricPathBase.heightPropertyKey,
              labelA: 'Width',
              labelB: 'Height',
              converter: TranslationValueConverter.instance,
            )

      // TODO: this is the spot to add the EditVertices button if the
      // intersectingCoreTypes contains a
      // CustomPath/PointsPath/WhateverWeCallItPath.
    ];
  }
}
