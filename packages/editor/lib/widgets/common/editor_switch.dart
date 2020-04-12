import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A toggle (on/off) switch with styling for the Rive editor.
class EditorSwitch extends StatelessWidget {
  static const Size size = Size(40, 20);
  static const double knobRadius = 8;
  static const double knobDiameter = knobRadius * 2;

  final bool isOn;
  final VoidCallback toggle;

  const EditorSwitch({
    @required this.isOn,
    this.toggle,
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return GestureDetector(
      onTapDown: (_) => toggle(),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.toggleBackground,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Align(
              alignment: isOn == null
                  ? Alignment.center
                  : isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: SizedBox(
                width: knobDiameter,
                height: knobDiameter,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isOn != null && isOn 
                        ? theme.colors.toggleForeground
                        : theme.colors.toggleForegroundDisabled,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(knobRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
