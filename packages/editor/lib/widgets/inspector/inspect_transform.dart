import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';

/// Returns the inspector for Artboard selections.
class TransformInspectorBuilder extends ListenableInspectorBuilder {
  bool _isScaleLinked = false;
  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(TransformComponentBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      if (inspecting.intersectingCoreTypes.contains(NodeBase.typeKey))
        (context) => PropertyDual<double>(
              name: 'Position',
              objects: inspecting.components,
              propertyKeyA: NodeBase.xPropertyKey,
              propertyKeyB: NodeBase.yPropertyKey,
              labelA: 'X',
              labelB: 'Y',
            ),
      (context) => PropertyDual<double>(
            name: 'Scale',
            linkable: true,
            isLinked: _isScaleLinked,
            toggleLink: (isLinked) {
              _isScaleLinked = isLinked;
              notifyListeners();
            },
            objects: inspecting.components,
            propertyKeyA: TransformComponentBase.scaleXPropertyKey,
            propertyKeyB: TransformComponentBase.scaleYPropertyKey,
            labelA: 'X',
            labelB: 'Y',
          ),
      (context) => PropertySingle<double>(
            name: 'Rotate',
            objects: inspecting.components,
            propertyKey: TransformComponentBase.rotationPropertyKey,
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
        (context) => PropertyDual<double>(
              name: 'Size',
              linkable: true,
              objects: inspecting.components,
              propertyKeyA: ParametricPathBase.widthPropertyKey,
              propertyKeyB: ParametricPathBase.heightPropertyKey,
              labelA: 'Width',
              labelB: 'Height',
            )

      // TODO: this is the spot to add the EditVertices button if the
      // intersectingCoreTypes contains a
      // CustomPath/PointsPath/WhateverWeCallItPath.
    ];
  }
}
