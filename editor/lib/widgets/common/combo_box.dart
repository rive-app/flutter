import 'package:flutter/material.dart';
import 'package:rive_editor/rive/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef ChooseOption<T> = void Function(T);
typedef OptionToLabel<T> = String Function(T);

class _ComboOption<T> extends PopupListItem {
  final T option;
  final ChooseOption<T> choose;

  _ComboOption(this.option, this.choose)
      : select = (() => choose?.call(option));

  @override
  bool get canSelect => true;

  @override
  double get height => 35;

  @override
  List<PopupListItem> get popup => null;

  @override
  ChangeNotifier get rebuildItem => null;

  @override
  final SelectCallback select;
}

class ComboBox<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final bool chevron;
  final bool underline;
  final Color valueColor;
  final bool expanded;
  final double popupWidth;
  final ChooseOption<T> chooseOption;
  final OptionToLabel<T> toLabel;

  const ComboBox({
    Key key,
    this.value,
    this.options,
    this.chevron = true,
    this.underline = true,
    this.valueColor = Colors.white,
    this.expanded = true,
    this.popupWidth,
    this.chooseOption,
    this.toLabel,
  }) : super(key: key);

  Widget _chevron(Widget child, {RiveThemeData theme}) {
    if (chevron) {
      return Row(
        children: [
          _expand(child),
          const SizedBox(width: 8),
          TintedIcon(
            color: theme.colors.toolbarButton,
            icon: 'dropdown-no-space',
          ),
        ],
      );
    }
    return child;
  }

  Widget _expand(Widget child) => expanded ? Expanded(child: child) : child;

  Widget _underline(Widget child, {RiveThemeData theme}) {
    if (underline) {
      return Container(
        padding: const EdgeInsets.only(bottom: 3),
        child: child,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colors.separator,
              width: 1,
            ),
          ),
        ),
      );
    }
    return child;
  }

  static const double chevronWidth = 5;
  static const double horizontalPadding = 15;

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return _expand(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          var width = popupWidth;
          if (width == null) {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            width = renderBox.size.width;
            // add chevron dimensions
            if (chevron) {
              // chevron is 5 pixels wide
              width += horizontalPadding + chevronWidth;
            }
          }

          // Wrap our items in PopupListItem.
          var items = options
              .map((option) => _ComboOption(option, chooseOption))
              .toList(growable: false);

          ListPopup<_ComboOption<T>>.show(
            context,
            offset: const Offset(-horizontalPadding, -40),
            margin: 5,
            showArrow: false,
            items: items,
            itemBuilder: (context, item, isHovered) => Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: horizontalPadding, right: horizontalPadding),
                child: Text(
                  toLabel == null
                      ? item.option.toString()
                      : toLabel(item.option),
                  style: TextStyle(
                    fontFamily: 'Roboto-Light',
                    fontSize: 13,
                    color: isHovered || value == item.option
                        ? Colors.white
                        : const Color(0xFF8C8C8C),
                  ),
                ),
              ),
            ),
            width: width,
          );
        },
        child: _underline(
          _chevron(
            Text(
              toLabel == null ? value.toString() : toLabel(value),
              style: theme.textStyles.basic.copyWith(color: valueColor),
            ),
            theme: theme,
          ),
          theme: theme,
        ),
      ),
    );
  }
}
