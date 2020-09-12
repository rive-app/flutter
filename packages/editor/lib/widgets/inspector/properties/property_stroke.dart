import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/converters/percentage_input_converter.dart';
import 'package:rive_editor/widgets/common/converters/string_value_converter.dart';
import 'package:rive_editor/widgets/common/core_editor_switch.dart';
import 'package:rive_editor/widgets/common/core_multi_toggle.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_component.dart';
import 'package:rive_core/shapes/paint/stroke.dart';
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout_title.dart';
import 'package:rive_editor/widgets/properties_builder.dart';
import 'package:rive_core/shapes/paint/trim_path.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

/// Uses the InspectorPopoutComponent to build a row in the inspector for
/// editing a color fill on a shape.
class PropertyStroke extends StatelessWidget {
  static const double inputWidth = 70;
  final Iterable<Stroke> strokes;
  final InspectingColor inspectingColor;

  const PropertyStroke({
    @required this.strokes,
    @required this.inspectingColor,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorPopoutComponent(
      components: strokes,
      prefix: (context) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: InspectorColorSwatch(
          inspectorContext: context,
          inspectingColor: inspectingColor,
        ),
      ),
      isVisiblePropertyKey: ShapePaintBase.isVisiblePropertyKey,
      popoutBuilder: (context) => PropertiesBuilder(
        objects: strokes,
        getValue: _trimPathForStroke,
        listen: (Stroke stroke, enabled, callback) {
          if (enabled) {
            stroke.effectChanged.addListener(callback);
          } else {
            stroke.effectChanged.removeListener(callback);
          }
        },
        builder: (context, TrimPathMode trimPathMode, _) {
          var trimPaths = <TrimPath>[];
          for (final stroke in strokes) {
            if (stroke.effect is! TrimPath) {
              trimPaths.clear();
              break;
            }
            trimPaths.add(stroke.effect as TrimPath);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InspectorPopoutTitle(titleKey: 'stroke_options'),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Name',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: inputWidth,
                    child: CoreTextField(
                      objects: strokes,
                      propertyKey: ComponentBase.namePropertyKey,
                      converter: StringValueConverter.instance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Cap',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  CoreMultiToggle(
                    objects: strokes,
                    propertyKey: StrokeBase.capPropertyKey,
                    options: const [
                      StrokeCap.butt,
                      StrokeCap.round,
                      StrokeCap.square,
                    ],
                    toIcon: (StrokeCap cap) {
                      switch (cap) {
                        case StrokeCap.butt:
                          return PackedIcon.capNone;
                        case StrokeCap.round:
                          return PackedIcon.capRound;
                        case StrokeCap.square:
                          return PackedIcon.capSquare;
                      }
                      return null;
                    },
                    toCoreValue: (StrokeCap strokeCap) => strokeCap.index,
                    fromCoreValue: (int value) => StrokeCap.values[value],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Join',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  CoreMultiToggle(
                    objects: strokes,
                    propertyKey: StrokeBase.joinPropertyKey,
                    options: const [
                      StrokeJoin.round,
                      StrokeJoin.bevel,
                      StrokeJoin.miter,
                    ],
                    toIcon: (StrokeJoin strokeJoin) {
                      switch (strokeJoin) {
                        case StrokeJoin.bevel:
                          return PackedIcon.joinBevel;
                        case StrokeJoin.round:
                          return PackedIcon.joinRound;
                        case StrokeJoin.miter:
                          return PackedIcon.joinMiter;
                      }
                      return null;
                    },
                    toCoreValue: (StrokeJoin strokeJoin) => strokeJoin.index,
                    fromCoreValue: (int value) => StrokeJoin.values[value],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Trim Path',
                    style:
                        RiveTheme.of(context).textStyles.inspectorPropertyLabel,
                  ),
                  const SizedBox(width: 20),
                  ComboBox(
                    value: trimPathMode,
                    options: TrimPathMode.values,
                    chevron: true,
                    underline: true,
                    change: (TrimPathMode value) {
                      if (strokes.isEmpty) {
                        return;
                      }

                      var core = strokes.first.context;
                      core.batchAdd(() {
                        for (final stroke in strokes) {
                          if (value == TrimPathMode.none) {
                            if (stroke.effect != null) {
                              var coreObject = stroke.effect as Component;
                              coreObject.remove();
                            }
                          } else if (stroke.effect is! TrimPath) {
                            // If we didn't have a trim path and we want one (mode
                            // != off), make one.
                            var trimPath = TrimPath()..mode = value;
                            core.addObject(trimPath);
                            stroke.appendChild(trimPath);
                          } else {
                            (stroke.effect as TrimPath).mode = value;
                          }
                        }
                      });
                      core.captureJournalEntry();

                      // Force focus back to the main context so that we can
                      // immediately undo this change if we want to by hitting
                      // ctrl/comamnd z.
                      RiveContext.find(context).focus();
                    },
                    toLabel: (TrimPathMode mode) => mode == null
                        ? ''
                        : UIStrings.find(context).withKey(describeEnum(mode)) ??
                            '???',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Start',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: inputWidth,
                    child: CoreTextField(
                      objects: trimPaths,
                      propertyKey: TrimPathBase.startPropertyKey,
                      converter: ClampedPercentageInputConverter.instance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'End',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: inputWidth,
                    child: CoreTextField(
                      objects: trimPaths,
                      propertyKey: TrimPathBase.endPropertyKey,
                      converter: ClampedPercentageInputConverter.instance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Offset',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: inputWidth,
                    child: CoreTextField(
                      objects: trimPaths,
                      propertyKey: TrimPathBase.offsetPropertyKey,
                      converter: PercentageInputConverter.instance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      'Transform Affects',
                      style: RiveTheme.of(context)
                          .textStyles
                          .inspectorPropertyLabel,
                    ),
                  ),
                  const SizedBox(width: 20),
                  CoreEditorSwitch(
                    objects: strokes,
                    propertyKey: StrokeBase.transformAffectsStrokePropertyKey,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Abstracted way to determine the trim path mode for a stroke. This is
/// implemented like this to make it easier when we add more path effects like
/// dashing.
TrimPathMode _trimPathForStroke(Stroke stroke) {
  if (stroke.effect == null || stroke.effect is! TrimPath) {
    return TrimPathMode.none;
  }
  return (stroke.effect as TrimPath).mode;
}
