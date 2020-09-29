import 'package:flutter/material.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/common/multi_toggle.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_pill_button.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:utilities/list_equality.dart';

/// TODO: this inspector should track the last selection such that when the
/// vertices in the paths it is inspecting change, it can detect which vertices
/// were swapped for others (this can happen during an undo when vertices change
/// type). This will allow us to rebuild the selection with the swapped items so
/// that when you undo/redo you get back the 'same' selected items (actually
/// different but correspond to same vertices). This will only work with a
/// specific set of paths, when the selection changes that set, the previous
/// path cache needs to be cleared.
///
/// We can compare vertices (to determine if new ones match old ones) via their
/// childOrder (in a specific path which requires some kind of mapping).
///

/// Returns the inspector for
/// Artboard selections.
class VertexInspector extends ListenableInspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) => true;

  @override
  List<WidgetBuilder> expand(
      BuildContext panelContext, InspectionSet inspecting) {
    // We assume inspection set has nothing but vertices in it, so filter
    // anything else out (paths may end up here too).
    var vertices =
        inspecting.components.whereType<PathVertex>().toList(growable: false);
    return [
      (context) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
          ),
          child: InspectorPillButton(
            label: 'Done Editing',
            icon: PackedIcon.popupCheck,
            press: () {
              ActiveFile.find(context).vertexEditor.doneEditing();
            },
          ),
        );
      },
      (context) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 10,
            bottom: 0,
            left: 20,
            right: 20,
          ),
          child: ValueListenableBuilder<Iterable<PointsPath>>(
            valueListenable:
                ActiveFile.of(context).vertexEditor.editingPathsListenable,
            builder: (context, paths, _) => CorePropertiesBuilder(
              propertyKey: PointsPathBase.isClosedPropertyKey,
              objects: paths,
              builder: (context, bool isClosed, _) {
                bool isClosedValue = isClosed ?? false;
                return InspectorPillButton(
                  label: isClosedValue ? 'Open Path' : 'Close Path',
                  icon: isClosedValue
                      ? PackedIcon.pathOpen
                      : PackedIcon.pathClose,
                  press: () {
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
      (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 20,
          ),
          child: InspectorPillButton(
            label: 'Reverse Direction',
            icon: PackedIcon.pathReverse,
            press: () {
              var paths = ActiveFile.find(context).vertexEditor.editingPaths;
              for (final path in paths) {
                path.reversePoints();
              }
              paths.first.context.captureJournalEntry();
            },
          ),
        );
      },
      InspectorBuilder.divider,
      (context) {
        const typeIcons = {
          StraightVertexBase.typeKey: PackedIcon.vertexStraight,
          CubicMirroredVertexBase.typeKey: PackedIcon.vertexMirrored,
          CubicDetachedVertexBase.typeKey: PackedIcon.vertexDetached,
          CubicAsymmetricVertexBase.typeKey: PackedIcon.vertexAsymmetric,
        };
        int vertexType = equalValue<PathVertex, int>(
            vertices, (PathVertex vertex) => vertex.coreType);

        var uiStrings = UIStrings.of(context);
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
          child: MultiToggle(
            value: vertexType,
            options: typeIcons.keys,
            toIcon: (int type) => typeIcons[type],
            toTip: (int type) {
              switch (type) {
                case StraightVertexBase.typeKey:
                  return Tip.above(
                    label: uiStrings.withKey('vertex-straight'),
                  );
                  break;
                case CubicMirroredVertexBase.typeKey:
                  return Tip.above(
                    label: uiStrings.withKey('vertex-mirrored'),
                  );
                  break;
                case CubicDetachedVertexBase.typeKey:
                  return Tip.above(
                    label: uiStrings.withKey('vertex-detached'),
                  );
                  break;
                case CubicAsymmetricVertexBase.typeKey:
                  return Tip.above(
                    label: uiStrings.withKey('vertex-asymmetric'),
                  );
                  break;
              }
              return null;
            },
            expand: true,
            padding: const EdgeInsets.all(3),
            change: (int type) => _changeVertexType(
              context,
              type,
              vertices,
            ),
          ),
        );
      },
      (context) => PropertyDual<double>(
            name: 'Position',
            objects: vertices,
            propertyKeyA: PathVertexBase.xPropertyKey,
            propertyKeyB: PathVertexBase.yPropertyKey,
            labelA: 'X',
            labelB: 'Y',
          ),
      if (inspecting.intersectingCoreTypes.contains(StraightVertexBase.typeKey))
        // All straight vertices, show corner...
        (context) {
          return PropertySingle(
            name: 'Corner',
            objects: vertices,
            propertyKey: StraightVertexBase.radiusPropertyKey,
            converter: TranslationValueConverter.instance,
          );
        },
      if (inspecting.intersectingCoreTypes
          .contains(CubicMirroredVertexBase.typeKey))
        // All mirrored...
        (context) {
          return PropertyDual<double>(
            name: 'Bezier',
            objects: vertices,
            propertyKeyA: CubicMirroredVertexBase.rotationPropertyKey,
            propertyKeyB: CubicMirroredVertexBase.distancePropertyKey,
            labelA: 'Angle',
            labelB: 'Length',
          );
        },
      if (inspecting.intersectingCoreTypes
          .contains(CubicAsymmetricVertexBase.typeKey)) ...[
        (context) => PropertyDual<double>(
              name: 'Bezier',
              objects: vertices,
              propertyKeyA: CubicAsymmetricVertexBase.rotationPropertyKey,
              propertyKeyB: CubicAsymmetricVertexBase.inDistancePropertyKey,
              labelA: 'Angle',
              labelB: 'Length In',
            ),
        (context) => PropertyDual<double>(
              name: '',
              objects: vertices,
              propertyKeyA: null,
              propertyKeyB: CubicAsymmetricVertexBase.outDistancePropertyKey,
              labelB: 'Length Out',
            ),
      ],
      if (inspecting.intersectingCoreTypes
          .contains(CubicDetachedVertexBase.typeKey)) ...[
        // All mirrored...
        (context) {
          return PropertyDual<double>(
            name: 'Bezier',
            objects: vertices,
            propertyKeyA: CubicDetachedVertexBase.inRotationPropertyKey,
            propertyKeyB: CubicDetachedVertexBase.inDistancePropertyKey,
            labelA: 'Angle In',
            labelB: 'Length In',
          );
        },
        (context) {
          return PropertyDual<double>(
            name: '',
            objects: vertices,
            propertyKeyA: CubicDetachedVertexBase.outRotationPropertyKey,
            propertyKeyB: CubicDetachedVertexBase.outDistancePropertyKey,
            labelA: 'Angle Out',
            labelB: 'Length Out',
          );
        },
      ],
    ];
  }

  void _changeVertexType(
      BuildContext context, int vertexType, Iterable<PathVertex> vertices) {
    if (vertices.isEmpty) {
      // Don't do anything if there's nothing selected or the option is
      // already selected.
      return;
    }
    var file = ActiveFile.find(context);
    var core = file.core;
    var newVertices = <PathVertex>{};

    // Don't auto key when swapping the vertex type as it changes core
    // properties that we don't want animated in this case.
    var suppression = core.suppressAutoKey();
    core.batchAdd(() {
      for (final vertex in vertices.toList()) {
        var newVertex = core.makeCoreInstance(vertexType) as PathVertex;
        newVertex.x = vertex.x;
        newVertex.y = vertex.y;

        var next = vertex.replaceWith(newVertex);

        if (newVertex is CubicVertex) {
          // This only happens when we're going from corner->cubic.
          var toNext =
              Vec2D.subtract(Vec2D(), next.translation, vertex.translation);
          var length = Vec2D.length(toNext);

          Vec2D.normalize(toNext, toNext);

          if (vertex is CubicVertex) {
            // The vertex we are converting from was already cubic, try copying in/out.
            newVertex.inPoint = vertex.inPoint;
            newVertex.outPoint = vertex.outPoint;
          } else {
            // The vertex we're converting from is not cubic.
            // Just align the in towards the next and mirror out.
            newVertex.inPoint = Vec2D.fromValues(
              newVertex.x - toNext[0] * length * 0.25,
              newVertex.y - toNext[1] * length * 0.25,
            );
            newVertex.outPoint = Vec2D.fromValues(
              newVertex.x + toNext[0] * length * 0.25,
              newVertex.y + toNext[1] * length * 0.25,
            );
          }
        }
        newVertices.add(newVertex);
        // TODO: seem to sometimes get a case related to #740 where the
        // number of vertices in the path increases by one (doesn't remove
        // the existing vertex that we're trying to replace with). Was
        // printing (newVertex.parent as PointsPath).vertices.length to try
        // to figure this out here. Can't find a repro yet and it seems to
        // either be a fluke due to hot reloads or some super rare edge case
        // which would be nice to fix up...
      }
    });
    var selection = file.selection.items.toSet();
    selection.addAll(newVertices.map((vertex) => vertex.stageItem));
    file.selection.selectMultiple(selection);
    core.captureJournalEntry();
    suppression.restore();
  }
}
