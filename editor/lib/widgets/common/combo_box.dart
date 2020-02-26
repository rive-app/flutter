import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// A multi-choice popup input widget. Has styling options for all the various
/// Rive use cases (chevron and underline are toggleable and text color is
/// configurable).) It can also optionally provide type-ahead logic and act as
/// text inputfield that filters the list of available options. Arrow keys can
/// be used to select items in the list. Enter to select, esc to cancel/exit.
class ComboBox<T> extends StatefulWidget {
  final T value;
  final List<T> options;
  final bool chevron;
  final bool underline;
  final Color valueColor;
  final bool expanded;
  final double popupWidth;
  final ChooseOption<T> chooseOption;
  final OptionToLabel<T> toLabel;
  final bool typeahead;

  static const double _chevronWidth = 5;
  static const double _horizontalPadding = 15;

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
    this.typeahead = false,
  }) : super(key: key);

  @override
  _ComboBoxState createState() => _ComboBoxState<T>();
}

class _ComboBoxState<T> extends State<ComboBox<T>> {
  ListPopup<_ComboOption<T>> _popup;
  TextEditingController _controller;
  FocusNode _focusNode;

  bool get isOpen => _popup?.isOpen ?? false;

  Widget _chevron(Widget child, {RiveThemeData theme}) {
    if (widget.chevron) {
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

  Widget _expand(Widget child) =>
      widget.expanded ? Expanded(child: child) : child;

  Widget _underline(Widget child, {RiveThemeData theme}) {
    if (widget.underline) {
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

  Widget _typeahead(Widget child, {RiveThemeData theme}) {
    return widget.typeahead && isOpen
        ? RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) {
              if (event is RawKeyDownEvent) {
                // Seems like the TextField doesn't internally lose focus when
                // esc is pressed, so we handle this manually here.
                if (event.physicalKey == PhysicalKeyboardKey.escape) {
                  _close();
                } else if (event.physicalKey == PhysicalKeyboardKey.arrowDown) {
                  _popup?.focusDown();
                } else if (event.physicalKey == PhysicalKeyboardKey.arrowUp) {
                  _popup?.focusUp();
                }
              }
            },
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _textInputChanged,
              onSubmitted: (text) {
                widget.chooseOption(_popup.focus.option);
              },
              style: theme.textStyles.basic.copyWith(color: widget.valueColor),
              textAlignVertical: TextAlignVertical.top,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                hintText: label,
                hintStyle:
                    theme.textStyles.basic.copyWith(color: widget.valueColor),
                isDense: true,
                floatingLabelBehavior: FloatingLabelBehavior.never,
                border: InputBorder.none,
                filled: false,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          )
        : child;
  }

  void _opened() {
    _focusNode?.removeListener(_focusChange);
    if (widget.typeahead) {
      _focusNode = FocusNode(canRequestFocus: true);
      _focusNode.addListener(_focusChange);
      _controller = TextEditingController(text: '');
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode?.removeListener(_focusChange);
    super.dispose();
  }

  void _close() {
    _focusNode?.removeListener(_focusChange);
    _focusNode = null;
    _popup?.close();
    setState(() {
      _popup = null;
    });
  }

  void _focusChange() {
    if (!_focusNode.hasPrimaryFocus) {
      _close();
    } else {
      _controller?.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }
  }

  Future<void> _textInputChanged(String value) async {
    var list = await _filter(value);
    // Wrap our items in PopupListItem.

    var values = list
        .map((option) => _ComboOption(option, widget.chooseOption))
        .toList(growable: false);
    _popup.values.value = values;
    if (values.isNotEmpty) {
      _popup.focus = values.first;
    }
  }

  Future<List<T>> _filter(String value) async {
    return widget.options
        .where((item) =>
            itemLabel(item).contains(RegExp(value, caseSensitive: false)))
        .toList(growable: false);
  }

  String itemLabel(T item) => item == null
      ? ''
      : widget.toLabel == null ? item.toString() : widget.toLabel(item);

  String get label => itemLabel(widget.value);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return _expand(
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          var width = widget.popupWidth;
          if (width == null) {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            width = renderBox.size.width;
            // add chevron dimensions
            if (widget.chevron) {
              // chevron is 5 pixels wide
              width += ComboBox._horizontalPadding + ComboBox._chevronWidth;
            }
          }

          // Wrap our items in PopupListItem.
          var items = widget.options
              .map((option) => _ComboOption(option, widget.chooseOption))
              .toList(growable: false);

          setState(() {
            _popup = ListPopup<_ComboOption<T>>.show(
              context,
              handleKeyPresses: !widget.typeahead,
              offset: Offset(-ComboBox._horizontalPadding,
                  widget.typeahead ? 0 : widget.underline ? -34 : -30),
              margin: 5,
              showArrow: false,
              items: items,
              itemBuilder: (context, item, isHovered) => Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: ComboBox._horizontalPadding,
                      right: ComboBox._horizontalPadding),
                  child: Text(
                    widget.toLabel == null
                        ? item.option.toString()
                        : widget.toLabel(item.option),
                    style: theme.textStyles.basic.copyWith(
                      color: isHovered || widget.value == item.option
                          ? Colors.white
                          : const Color(0xFF8C8C8C),
                    ),
                  ),
                ),
              ),
              width: width,
            );
            _opened();
          });
        },
        child: _underline(
          _chevron(
            _typeahead(
              Text(
                label,
                style:
                    theme.textStyles.basic.copyWith(color: widget.valueColor),
              ),
              theme: theme,
            ),
            theme: theme,
          ),
          theme: theme,
        ),
      ),
    );
  }
}
