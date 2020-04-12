import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef ChooseOption<T> = void Function(T);
typedef OptionToIcon<T> = String Function(T);

/// A multi toggle that displays icons in a row for each option.
class MultiToggle<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final ChooseOption<T> change;
  final OptionToIcon<T> toIcon;

  const MultiToggle({
    @required this.value,
    @required this.options,
    @required this.toIcon,
    this.change,
    Key key,
  }) : super(key: key);

  Widget _select(Widget icon, Color background) {
    return background != null
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: const BorderRadius.all(
                Radius.circular(15),
              ),
            ),
            child: icon,
          )
        : icon;
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.toggleBackground,
        borderRadius: const BorderRadius.all(
          Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            for (final option in options)
              _select(
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => change?.call(option),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: TintedIcon(
                      color: option == value
                          ? const Color(0xFFFFFFFF)
                          : theme.colors.inspectorTextColor,
                      icon: toIcon(option),
                    ),
                  ),
                ),
                option == value ? theme.colors.toggleForegroundDisabled : null,
              ),
          ],
        ),
      ),
    );
  }
}
