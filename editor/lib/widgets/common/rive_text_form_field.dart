import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:window_utils/window_utils.dart';

class RiveTextFormField extends StatefulWidget {
  const RiveTextFormField({
    @required this.initialValue,
    @required this.onComplete,
    this.hintText = '',
    this.labelText,
    this.edgeInsets = EdgeInsets.zero,
    this.isNumeric = true,
    this.showDegree = false,
    this.canDrag = true,
    this.controller,
    this.focusNode,
    Key key,
  }) : super(key: key);

  final String hintText, labelText;
  final String initialValue;
  final FocusNode focusNode;
  final Function(String value, bool isDragging) onComplete;
  final EdgeInsets edgeInsets;
  final bool showDegree;
  final bool isNumeric;
  final bool canDrag;
  final TextEditingController controller;

  @override
  _RiveTextFormFieldState createState() => _RiveTextFormFieldState();
}

class _RiveTextFormFieldState extends State<RiveTextFormField> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _controller;
  String _cachedValue;
  bool _isEditing = false;
  FocusNode _focusNode;

  @override
  void initState() {
    _controller = widget?.controller ?? TextEditingController();
    _controller.text = widget.initialValue;
    if (widget.showDegree && widget.initialValue != '-') {
      _controller.text += '°';
    }
    _focusNode = widget?.focusNode ?? FocusNode();
    _focusNode.addListener(_updateFocusNode);
    super.initState();
  }

  void _updateFocusNode() {
    if (!_focusNode.hasFocus) {
      _formKey.currentState.save();
      if (widget.isNumeric && widget.canDrag) {
        WindowUtils.resetCursor();
      }
    } else {
      _isEditing = false;
      try {
        final extentOffset = _controller.text.length;
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: extentOffset,
        );
      } on Exception catch (e) {
        print('Error Updating Text Selection: $e');
      }
    }
  }

  @override
  void didUpdateWidget(RiveTextFormField oldWidget) {
    if (oldWidget.initialValue != widget.initialValue) {
      if (widget.initialValue != _controller.text) {
        _controller.text = widget.initialValue;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    // _focusNode.dispose();
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!_isEditing && widget.canDrag) {
          WindowUtils.setCursor(CursorType.resizeUpDown);
        }
      },
      onExit: (_) {
        WindowUtils.resetCursor();
      },
      child: GestureDetector(
        onVerticalDragStart: (details) {
          if (!widget.canDrag) return;
          _cachedValue = _controller.text;
        },
        onVerticalDragEnd: (details) {
          if (!widget.canDrag) return;
          _cachedValue = null;
          widget.onComplete(_controller.text, false);
        },
        onVerticalDragUpdate: (details) {
          if (!widget.canDrag) return;
          if (widget.isNumeric) {
            final _value = double.tryParse(_cachedValue.replaceAll('°', ''));
            final _newValue = _value + details.primaryDelta;
            _cachedValue = _newValue.toString();
            _controller.text = _cachedValue;
            widget.onComplete(_controller.text, true);
          }
        },
        onTap: () {
          _focusNode.requestFocus();
          if (!_isEditing && widget.isNumeric) {
            _isEditing = true;
            WindowUtils.setCursor(CursorType.cross);
          }
        },
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: TextFormField(
              key: widget.key,
              onTap: () {},
              focusNode: _focusNode,
              controller: _controller,
              inputFormatters: [
                if (widget.isNumeric)
                  RegExInputFormatter.withRegex(
                      "^\$|^(0|([1-9][0-9]{0,}))(\\.[0-9]{0,})?\$"),
              ],
              textAlignVertical: TextAlignVertical.top,
              scrollPadding: EdgeInsets.zero,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: widget.edgeInsets,
                hintText: widget.hintText,
                labelText: widget.labelText,
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        width: 2,
                        color: RiveTheme.of(context).colors.separator)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                        width: 2,
                        color: RiveTheme.of(context).colors.separatorActive)),
                hintStyle:
                    RiveTheme.of(context).textStyles.inspectorPropertyValue,
              ),
              style: RiveTheme.of(context).textStyles.inspectorPropertyValue,
              onChanged: (val) {
                // print('onChanged: $val');
              },
              onSaved: (val) {
                String _value = widget.initialValue;
                if (val.isEmpty) {
                  _value = widget.initialValue;
                  _controller.text = _value;
                } else {
                  _value = val;
                }
                if (_value.isNotEmpty) {
                  widget.onComplete(_value.replaceAll('°', ''), false);
                  _focusNode.unfocus(disposition: UnfocusDisposition.scope);
                }
              },
              onEditingComplete: () {
                _formKey.currentState.save();
              },
              onFieldSubmitted: (_) {
                _formKey.currentState.save();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RegExInputFormatter implements TextInputFormatter {
  final RegExp _regExp;

  RegExInputFormatter._(this._regExp);

  factory RegExInputFormatter.withRegex(String regexString) {
    try {
      final regex = RegExp(regexString);
      return RegExInputFormatter._(regex);
    } on Exception catch (e) {
      print('Error Regex: $e');
      return null;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final oldValueValid = _isValid(oldValue.text);
    final newValueValid = _isValid(newValue.text);
    if (oldValueValid && !newValueValid) {
      return oldValue;
    }
    return newValue;
  }

  bool _isValid(String value) {
    try {
      final matches = _regExp.allMatches(value);
      for (final match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
      return false;
    } on Exception catch (e) {
      print('Invalid Regex: $e');
      return true;
    }
  }
}

abstract class InputConverter {
  String toDisplayValue(double value, [int fractionDigits]);
  double toInputValue(double value);
  double fromDisplayValue(String value);
  double fromInputValue(String string);
  bool get allowDrag;
  double get dragScale;
}

class RotationInputConverter extends InputConverter {
  RotationInputConverter._();

  @override
  String toDisplayValue(double value, [int fractionDigits]) {
    double _value = (value * 180.0 / math.pi * 100.0).floor() / 100.0;
    if (fractionDigits != null) {
      return _value.toStringAsFixed(fractionDigits) + " °";
    }
    return _value.toString() + " °";
  }

  @override
  double toInputValue(double value) {
    return value * 180.0 / math.pi;
  }

  @override
  double fromDisplayValue(String value) {
    final _value = double.tryParse(value) / 180.0 * math.pi;
    if (_value != null && _value.isNaN) {
      throw Exception('Invalid input');
    }
    return _value;
  }

  @override
  double fromInputValue(String string) {
    return fromDisplayValue(string);
  }

  @override
  bool get allowDrag {
    return true;
  }

  @override
  double get dragScale {
    return 0.1 / 180.0 * math.pi;
  }
}
