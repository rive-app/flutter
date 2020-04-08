import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'editor_text_field.dart';

typedef ChooseOption<T> = void Function(T);
typedef OptionToLabel<T> = String Function(T);
typedef OptionRetriever<T> = Future<List<T>> Function(String);
typedef OptionBuilder<T> = Widget Function(
    BuildContext context, bool isHovered, T option);

class _ComboOption<T> extends PopupListItem {
  final T option;
  final ChooseOption<T> choose;

  _ComboOption(this.option, this.choose)
      : select = (() => choose?.call(option));

  @override
  bool get canSelect => true;

  @override
  bool get dismissAll => false;

  @override
  double get height => 35;

  @override
  List<PopupListItem> get popup => null;

  @override
  ChangeNotifier get rebuildItem => null;

  @override
  final SelectCallback select;
}

/// Sizing options for the combobox. [expanded] means to expand this combobox to
/// take up the maximum available space in the parent. [collapsed] means to take
/// up the minimum horizontal space required to let the current selection
/// display without wrapping. [content] means to use the length of the widest
/// label in the list of options.
enum ComboSizing { expanded, collapsed, content }

/// Sizing options for the popup. [combo] means to use the dimensions of the
/// combo box itself, or the specified [ComboBox.popupWidth] when provided.
/// [content] means to compute the intrinsic width of the rendered popup items
/// (N.B this effectively disabled the scrollview in the popup as vertical
/// scrollviews cannot size based on the width of their content)
enum ComboPopupSizing { content, combo }

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
  final Color underlineColor;
  final Color valueColor;
  final Color cursorColor;
  final ComboSizing sizing;
  final ComboPopupSizing popupSizing;
  final double popupWidth;
  final ChooseOption<T> change;
  final OptionToLabel<T> toLabel;
  final OptionBuilder<T> leadingBuilder;
  final OptionRetriever<T> retriever;
  final bool typeahead;
  final Alignment alignment;
  final EdgeInsetsGeometry contentPadding;
  final Event trigger;
  final TextStyle valueTextStyle;

  static const double _chevronWidth = 5;
  static const double _horizontalPadding = 15;

  const ComboBox({
    Key key,
    this.value,
    this.options,
    this.retriever,
    this.chevron = true,
    this.underline = true,
    this.valueColor = Colors.white,
    this.sizing = ComboSizing.expanded,
    this.popupSizing = ComboPopupSizing.combo,
    this.popupWidth,
    this.change,
    this.toLabel,
    this.leadingBuilder,
    this.underlineColor,
    this.contentPadding,
    this.typeahead = false,
    this.alignment = Alignment.topLeft,
    this.trigger,
    this.cursorColor,
    this.valueTextStyle,
  }) : super(key: key);

  @override
  _ComboBoxState createState() => _ComboBoxState<T>();
}

class _ComboBoxState<T> extends State<ComboBox<T>> {
  ListPopup<_ComboOption<T>> _popup;
  TextEditingController _controller;
  FocusNode _focusNode;
  double _contentWidth;

  @override
  void initState() {
    super.initState();
    widget.trigger?.addListener(_trigger);
  }

  @override
  void dispose() {
    widget.trigger?.removeListener(_trigger);
    _focusNode?.removeListener(_focusChange);
    super.dispose();
  }

  @override
  void didUpdateWidget(ComboBox<T> oldWidget) {
    if (oldWidget.trigger != widget.trigger) {
      widget.trigger?.removeListener(_trigger);
      widget.trigger?.addListener(_trigger);
    }

    if (oldWidget.options != widget.options) {
      // Reset content size so it'll be re-computed.
      _contentWidth = null;
    }
    super.didUpdateWidget(oldWidget);
  }

  void _trigger() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    _open(renderBox.size);
  }

  /// Get the width of this combobox used for the [ComboSizing.content] option.
  /// This computes the widest label width in the list of options.
  double get contentWidth {
    if (_contentWidth != null) {
      return _contentWidth;
    }
    double width = 0;

    // Compute widest of all text labels.
    var textStyle = RiveThemeData().textStyles.basic;
    for (final option in widget.options) {
      final style = ui.ParagraphStyle(
          textAlign: TextAlign.left,
          fontFamily: textStyle.fontFamily,
          fontSize: textStyle.fontSize);
      ui.ParagraphBuilder builder = ui.ParagraphBuilder(style)
        ..pushStyle(textStyle.getTextStyle());
      var text = itemLabel(option);
      builder.addText(text);
      ui.Paragraph paragraph = builder.build();
      paragraph.layout(const ui.ParagraphConstraints(width: 2048));
      List<TextBox> boxes = paragraph.getBoxesForRange(0, text.length);
      var optionWidth = boxes.last.right - boxes.first.left + 1;
      if (optionWidth > width) {
        width = optionWidth;
      }
    }
    _contentWidth = width;
    return width;
  }

  bool get isOpen => _popup?.isOpen ?? false;

  Widget _chevron(Widget child, {RiveThemeData theme}) {
    if (widget.chevron) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _size(child),
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

  Widget _size(Widget child) {
    switch (widget.sizing) {
      case ComboSizing.collapsed:
        return child;
      case ComboSizing.expanded:
        return Expanded(child: child);
      case ComboSizing.content:
        return SizedBox(width: contentWidth, child: child);
    }
    return child;
  }

  Widget _expand(Widget child) {
    switch (widget.sizing) {
      case ComboSizing.expanded:
        return Expanded(child: child);
      case ComboSizing.collapsed:
        return child;
      case ComboSizing.content:
        return UnconstrainedBox(
          child: child,
          alignment: widget.alignment,
        );
    }
    return child;
  }

  Widget _underline(Widget child, {RiveThemeData theme}) {
    if (widget.underline) {
      return Underline(
        child: child,
        color: widget.underlineColor ?? theme.colors.separator,
      );
    }
    return child;
  }

  Widget _padding(Widget child) {
    if (widget.contentPadding != null) {
      return Padding(
        padding: widget.contentPadding,
        child: child,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 10,
              ),
              child: IntrinsicWidth(
                child: EditorTextField(
                  allowDrag: false,
                  color: widget.valueColor,
                  style: widget.valueTextStyle,
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _textInputChanged,
                  onSubmitted: (text) {
                    var option = _popup.focus.option;
                    _close();
                    widget.change(option);
                  },
                ),
              ),
            ),
          )
        : child;
  }

  void _opened() {
    _focusNode?.removeListener(_focusChange);
    if (widget.typeahead) {
      setState(() {
        _focusNode = FocusNode(canRequestFocus: true);
        _focusNode.addListener(_focusChange);
        _controller = TextEditingController(text: '');
        _focusNode.requestFocus();
      });
    }
  }

  void _open(Size size) {
    _popup?.close();

    var theme = RiveTheme.of(context);
    var width = widget.popupSizing == ComboPopupSizing.content
        ? null
        : widget.popupWidth ??
            size.width +
                (widget.chevron
                    ? ComboBox._horizontalPadding + ComboBox._chevronWidth
                    : 0);

    // Wrap our items in PopupListItem.
    var items = widget.options == null
        ? <_ComboOption<T>>[]
        : widget.options
            .map((option) => _ComboOption(option, widget.change))
            .toList(growable: false);

    setState(() {
      var offset = Offset(-ComboBox._horizontalPadding,
          widget.typeahead ? 0 : widget.underline ? -34 : -30);
      if (widget.contentPadding is EdgeInsets) {
        var p = widget.contentPadding as EdgeInsets;
        offset += Offset(p.left, -p.bottom);
      }

      _popup = ListPopup<_ComboOption<T>>.show(
        context,
        handleKeyPresses: !widget.typeahead,
        offset: offset,
        margin: 5,
        includeCloseGuard: true,
        showArrow: false,
        directionPadding: 0,
        items: items,
        itemBuilder: (context, item, isHovered) => Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ComboBox._horizontalPadding,
            ),
            child: widget.leadingBuilder != null
                ? Row(
                    children: [
                      widget.leadingBuilder(context, isHovered, item.option),
                      _optionItemText(
                        item.option,
                        isHovered,
                        theme.textStyles.basic,
                      ),
                    ],
                  )
                : _optionItemText(
                    item.option,
                    isHovered,
                    theme.textStyles.basic,
                  ),
          ),
        ),
        width: width,
      );
      _opened();
    });
  }

  Widget _optionItemText(T option, bool isHovered, TextStyle style) => Text(
        widget.toLabel == null ? option.toString() : widget.toLabel(option),
        style: style.copyWith(
          color: isHovered || widget.value == option
              ? Colors.white
              : const Color(0xFF8C8C8C),
        ),
      );

  void _close() {
    _controller?.clear();
    _focusNode?.removeListener(_focusChange);
    _popup?.close();
    setState(() {
      _popup = null;
      _focusNode = null;
      _controller = null;
    });
  }

  void _focusChange() {
    _placePopup();
    if (!_focusNode.hasPrimaryFocus) {
      _close();
    } else {
      _controller?.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }
  }

  Future<void> _textInputChanged(String value) async {
    var popup = _popup;
    var list = await _filter(value) ?? [];
    // Popup could've changed while we were waiting for results.
    if (popup != _popup) {
      return;
    }
    // Wrap our items in PopupListItem.
    var values = list
        .map((option) => _ComboOption(option, widget.change))
        .toList(growable: false);
    _popup.values.value = values;
    if (values.isNotEmpty) {
      _popup.focus = values.first;
    }
    _placePopup();
  }

  // Convenience method to trigger relayout of the type-ahead results.
  void _placePopup() => _popup?.arrowPopup?.contextRect?.updateRect(context);

  Future<List<T>> _filter(String value) async {
    if (widget.retriever != null) {
      return widget.retriever(value);
    }
    return widget.options
        .where((item) =>
            itemLabel(item).contains(RegExp(value, caseSensitive: false)))
        .toList(growable: false);
  }

  String itemLabel(T item) =>
      widget.toLabel == null ? item?.toString() ?? '' : widget.toLabel(item);

  String get label => itemLabel(widget.value);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return _expand(
      _ComboGestureDetector(
        open: _open,
        child: _underline(
          _chevron(
            _padding(
              _typeahead(
                Text(
                  label,
                  style: (widget.valueTextStyle ?? theme.textStyles.basic)
                      .copyWith(color: widget.valueColor),
                ),
                theme: theme,
              ),
            ),
            theme: theme,
          ),
          theme: theme,
        ),
      ),
    );
  }
}

/// We break the detector in its own widget so we can properly calculate the and
/// size of just the content that can be tapped on to report back to the combo
/// box widget itself. It uses those dimensions  to open a popup in the correct
/// location and of the correct size.
class _ComboGestureDetector extends StatelessWidget {
  final void Function(Size) open;
  final Widget child;

  const _ComboGestureDetector({
    @required this.open,
    @required this.child,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          RenderBox renderBox = context.findRenderObject() as RenderBox;

          open(renderBox.size);
        },
        child: child,
      );
}
