import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_color.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';

/// Returns the inspector for Artboard selections.
class ArtboardInspectorBuilder extends ListenableInspectorBuilder {
  bool _isSizeLinked = false;
  bool _isOriginLinked = false;

  @override
  bool validate(InspectionSet inspecting) =>
      inspecting.intersectingCoreTypes.contains(ArtboardBase.typeKey);

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
        (context) => PropertyDual(
              name: 'Position',
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.xPropertyKey,
              propertyKeyB: ArtboardBase.yPropertyKey,
              labelA: 'X',
              labelB: 'Y',
              converter: TranslationValueConverter.instance,
            ),
        (context) => PropertyDual(
              name: 'Size',
              linkable: true,
              isLinked: _isSizeLinked,
              toggleLink: (value) {
                _isSizeLinked = value;
                notifyListeners();
              },
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.widthPropertyKey,
              propertyKeyB: ArtboardBase.heightPropertyKey,
              labelA: 'Width',
              labelB: 'Height',
              converter: TranslationValueConverter.instance,
            ),
        (context) => PropertyDual(
              name: 'Origin',
              linkable: true,
              isLinked: _isOriginLinked,
              toggleLink: (value) {
                _isOriginLinked = value;
                notifyListeners();
              },
              objects: inspecting.components,
              propertyKeyA: ArtboardBase.originXPropertyKey,
              propertyKeyB: ArtboardBase.originYPropertyKey,
              labelA: 'X',
              labelB: 'Y',
              converter: TranslationValueConverter.instance,
            ),
        InspectorBuilder.divider,
        (context) => PropertyColor(
              name: 'Background',
              objects: inspecting.components,
              propertyKey: ArtboardBase.colorValuePropertyKey,
            ),
      ];
}
