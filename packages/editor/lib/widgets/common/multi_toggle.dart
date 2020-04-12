import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef ChooseOption<T> = void Function(T);
typedef OptionToIcon<T> = String Function(T);

/// A toggle (on/off) switch with styling for the Rive editor.
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

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.toggleBackground,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          children: [
            for (final option in options)
              TintedIcon(
                color: const Color(0xFFFFFFFF),
                icon: toIcon(option),
              )
          ],
        ),
      ),
    );
  }
}
