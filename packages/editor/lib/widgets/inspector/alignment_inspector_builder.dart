import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'inspector_builder.dart';

/// Expander for the alignment inspector.
class AlignmentInspectorBuilder extends InspectorBuilder {
  @override
  bool validate(InspectionSet inspecting) => true;

  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
    (context) => Padding(
          padding:
              const EdgeInsets.only(top: 12, bottom: 2, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              for (var i = 1; i <= 8; i++)
                Flexible(
                  flex: 1,
                  child: Container(
                    child: Transform.scale(
                      scale: 0.5,
                      child: TintedIcon(
                        color: RiveTheme.of(context)
                            .textStyles
                            .inspectorPropertyLabel
                            .color,
                        icon: 'align$i',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        )
  ];
}