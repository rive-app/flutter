import 'package:cursor/propagating_listener.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/points_path.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
import 'package:rive_editor/rive/stage/items/stage_path_vertex.dart';
import 'package:rive_editor/rive/stage/tools/transformers/translation/path_vertex_translate_transformer.dart';
import 'package:rive_editor/rive/stage/tools/transforming_tool.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_pill_button.dart';
import 'package:rive_editor/widgets/inspector/properties/property_dual.dart';
import 'package:rive_editor/widgets/inspector/properties/property_single.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/ui_strings.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
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
  List<WidgetBuilder> expand(InspectionSet inspecting) {
    return [
      (context) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 20,
            top: 20,
            right: 20,
          ),
          child: InspectorPillButton(
            label: 'Done Editing',
            icon: 'check',
            press: () {
              ActiveFile.find(context).vertexEditor.doneEditing();
            },
          ),
        );
      },
      (context) {
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
                return InspectorPillButton(
                  label: isClosedValue ? 'Open Path' : 'Close Path',
                  icon: isClosedValue ? 'path-open' : 'path-close',
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
      (context) => _VertexButtonDual(
            vertices: inspecting.components.cast<PathVertex>(),
            builder: (context, controlTypeValue, allowActive, vertices) {
              return Row(
                children: [
                  _VertexTypeButton(
                    vertexType: StraightVertexBase.typeKey,
                    icon: 'vertex-straight',
                    isActive: allowActive && controlTypeValue == null,
                    vertices: vertices,
                  ),
                  const SizedBox(width: 10),
                  _VertexTypeButton(
                    vertexType: CubicVertexBase.typeKey,
                    controlType: VertexControlType.mirrored,
                    icon: 'vertex-mirrored',
                    isActive: allowActive &&
                        controlTypeValue == VertexControlType.mirrored.index,
                    vertices: vertices,
                  ),
                ],
              );
            },
          ),
      (context) => _VertexButtonDual(
            vertices: inspecting.components.cast<PathVertex>(),
            builder: (context, controlTypeValue, allowActive, vertices) {
              return Row(
                children: [
                  _VertexTypeButton(
                    vertexType: CubicVertexBase.typeKey,
                    controlType: VertexControlType.detached,
                    icon: 'vertex-detached',
                    isActive: allowActive &&
                        controlTypeValue == VertexControlType.detached.index,
                    vertices: vertices,
                  ),
                  const SizedBox(width: 10),
                  _VertexTypeButton(
                    vertexType: CubicVertexBase.typeKey,
                    controlType: VertexControlType.asymmetric,
                    icon: 'vertex-assymetric',
                    isActive: allowActive &&
                        controlTypeValue == VertexControlType.asymmetric.index,
                    vertices: vertices,
                  ),
                ],
              );
            },
          ),
    ];
  }
}

class _VertexButtonDual extends StatelessWidget {
  final Iterable<PathVertex> vertices;
  final Widget Function(BuildContext context, int controlTypeValue,
      bool allowActive, Iterable<PathVertex> vertices) builder;

  const _VertexButtonDual({
    @required this.vertices,
    @required this.builder,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      propertyKey: CubicVertexBase.controlTypeValuePropertyKey,
      objects: vertices,
      builder: (context, int controlTypeValue, _) {
        bool allowActive = equalValue<PathVertex, VertexControlType>(
                vertices, (PathVertex vertex) => vertex.controlType) !=
            null;

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 10,
          ),
          child: builder(context, controlTypeValue, allowActive, vertices),
        );
      },
    );
  }
}

class _VertexTypeButton extends StatefulWidget {
  final int vertexType;
  final VertexControlType controlType;
  final String icon;
  final bool isActive;
  final Iterable<PathVertex> vertices;

  const _VertexTypeButton({
    Key key,
    this.vertexType,
    this.icon,
    this.isActive,
    this.controlType,
    this.vertices,
  }) : super(key: key);

  @override
  __VertexTypeButtonState createState() => __VertexTypeButtonState();
}

class __VertexTypeButtonState extends State<_VertexTypeButton> {
  bool _hasHover = false;

  bool get isDisabled => widget.vertices.isEmpty;
  Widget _listen(Widget child) {
    if (isDisabled) {
      return child;
    }
    return PropagatingListener(
      onPointerDown: (_) {
        if (widget.vertices.isEmpty) {
          return;
        }
        var file = ActiveFile.find(context);
        var core = file.core;
        var selection = file.selection.items.toSet();
        var newVertices = <PathVertex>{};

        core.batchAdd(() {
          for (final vertex in widget.vertices.toList()) {
            if (vertex.coreType != widget.vertexType) {
              var path = vertex.parent as PointsPath;

              var index = path.vertices.indexOf(vertex);
              var next = path.vertices[(index + 1) % path.vertices.length];

              selection.remove(vertex.stageItem);
              vertex.remove();
              var newVertex =
                  core.makeCoreInstance(widget.vertexType) as PathVertex;
              newVertex.x = vertex.x;
              newVertex.y = vertex.y;
              newVertex.childOrder = vertex.childOrder;
              if (newVertex is CubicVertex) {
                // This only happens when we're going from corner->cubic.
                var toNext = Vec2D.subtract(
                    Vec2D(), next.translation, vertex.translation);
                var length = Vec2D.length(toNext);

                Vec2D.normalize(toNext, toNext);

                // Just align the in towards the next and mirror out.

                newVertex.inX = newVertex.x - toNext[0] * length * 0.25;
                newVertex.inY = newVertex.y - toNext[1] * length * 0.25;
                newVertex.outX = newVertex.x + toNext[0] * length * 0.25;
                newVertex.outY = newVertex.y + toNext[1] * length * 0.25;
                newVertex.controlType = widget.controlType;
              }
              newVertices.add(newVertex);
              core.add(newVertex);
              newVertex.parent = path;

              // We need to replace the entire vertex with one of a different
              // type. This is messy because we also need it to maintain the
              // same order/index in the list.
            } else if (vertex is CubicVertex) {
              vertex.controlType = widget.controlType;
              // 0 move it to force the control points to update.
              var transformer = PathVertexTranslateTransformer();
              var details = DragTransformDetails(vertex.artboard, Vec2D());
              transformer.init(
                  {(vertex.stageItem as StagePathVertex).controlIn}, details);
              transformer.advance(details);
            }
          }
        });
        selection.addAll(newVertices.map((vertex) => vertex.stageItem));
        file.selection.selectMultiple(selection);
        core.captureJournalEntry();
      },
      child: MouseRegion(
        onEnter: (_) {
          if (widget.vertices.isEmpty) {
            return;
          }
          setState(() {
            _hasHover = true;
          });
        },
        onExit: (_) {
          if (widget.vertices.isEmpty) {
            return;
          }
          setState(() {
            _hasHover = false;
          });
        },
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return _listen(
      Container(
        width: 92,
        height: 70,
        decoration: widget.isActive && !isDisabled
            ? BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF57A5E0),
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              )
            : null,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TintedIcon(
                icon: widget.icon,
                color: !isDisabled && (_hasHover || widget.isActive)
                    ? theme.colors.vertexIconHover
                    : theme.colors.vertexIcon,
              ),
              const SizedBox(height: 7),
              Text(
                UIStrings.of(context).withKey(widget.icon),
                style: !isDisabled && (_hasHover || widget.isActive)
                    ? theme.textStyles.vertexTypeSelected
                    : theme.textStyles.vertexTypeLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
