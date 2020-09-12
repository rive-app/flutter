import 'package:flutter/widgets.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// A commonly reused pill button with label and icon for the inspector.
class InspectorPillButton extends StatelessWidget {
  final VoidCallback press;
  final Iterable<PackedIcon> icon;
  final String label;
  final bool accent;
  final Color textColor;

  const InspectorPillButton({
    Key key,
    this.press,
    this.icon,
    this.label,
    this.accent = false,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var colors = RiveTheme.of(context).colors;
    bool disabled = press == null;

    var color =
        accent ? colors.toolbarButtonSelected : colors.inspectorPillBackground;
    var disabledColor = colors.inspectorPillBackground;

    return IgnorePointer(
      ignoring: disabled,
      child: FlatIconButton(
        label: label,
        color: disabled ? disabledColor : color,
        hoverColor: colors.inspectorPillHover,
        textColor: textColor ??
            (disabled
                ? colors.inspectorPillDisabledText
                : colors.inspectorPillText),
        hoverTextColor: colors.activeText,
        icon: icon == null
            ? null
            : TintedIcon(
                icon: icon,
                color: colors.inspectorPillIcon,
              ),
        hoverIcon: icon == null
            ? null
            : TintedIcon(
                icon: icon,
                color: colors.activeText,
              ),
        onTap: press,
      ),
    );
  }
}
