import 'package:flutter/material.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Returns the inspector for Artboard selections.
class VertexInspector extends ListenableInspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) => true;

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) {
        var colors = RiveTheme.of(context).colors;
        return Padding(
          padding: const EdgeInsets.only(
            left: 20,
            top: 20,
            right: 20,
          ),
          child: FlatIconButton(
            label: 'Done Editing',
            color: colors.inspectorPillBackground,
            hoverColor: colors.inspectorPillHover,
            textColor: colors.inspectorPillText,
            icon: TintedIcon(
              icon: 'check',
              color: colors.inspectorPillIcon,
            ),
            onTap: () {
              ActiveFile.find(context).vertexEditor.doneEditing();
            },
          ),
        );
      },
      (context) {
        var colors = RiveTheme.of(context).colors;
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 20,
          ),
          child: ValueListenableBuilder<Iterable<PointsPath>>(
            valueListenable:
                ActiveFile.of(context).vertexEditor.editingPathsListenable,
            builder: (context, paths, _) => CorePropertiesBuilder(
              propertyKey: PointsPathBase.isClosedPropertyKey,
              objects: paths,
              builder: (context, bool isClosed, _) {
                bool isClosedValue = isClosed ?? false;
                return FlatIconButton(
                  label: isClosedValue ? 'Open Path' : 'Close Path',
                  color: colors.inspectorPillBackground,
                  hoverColor: colors.inspectorPillHover,
                  textColor: colors.inspectorPillText,
                  icon: TintedIcon(
                    icon: isClosedValue ? 'path-open' : 'path-close',
                    color: colors.inspectorPillIcon,
                  ),
                  onTap: () {
                    var closed = !isClosedValue;
                    for (final path in paths) {
                      path.isClosed = closed;
                    }
                    paths.first.context.captureJournalEntry();
                  },
                );
              },
            ),
          ),
        );
      },
      InspectorBuilder.divider,
      (context) => PropertyDual(
            name: 'Position',
            objects: inspecting.components,
            propertyKeyA: PathVertexBase.xPropertyKey,
            propertyKeyB: PathVertexBase.yPropertyKey,
            labelA: 'X',
            labelB: 'Y',
            converter: TranslationValueConverter.instance,
          ),
      (context) => PropertySingle(
            name: 'Corner',
            objects: inspecting.components,
            propertyKey: StraightVertexBase.radiusPropertyKey,
            converter: TranslationValueConverter.instance,
          ),
    ];
  }
}
