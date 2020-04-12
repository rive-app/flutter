import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// A ComboBox that manipulates core properties. This assumes that the core
/// value will differ in type from the displayed value. This may not always be
/// the case, but it usually is. For example, most enums get stored as an
/// integer core value. We'll want the UI to mostly deal with the enum value (in
/// the options list, when selecting the value, etc) but this CoreComboBox needs
/// a little help to resolve what the core value to write for that enum should
/// be. That's why it provides the [toCoreValue]/[fromCoreValue] methods. [T] is
/// the UI friendly value (usually a list of enums or a list of objects) while
/// [K] is the backing core property (usually an integer, but not always).
///
/// The [propertyKey] is hander over to [CorePropertiesBuilder] to extract the
/// associated field data to be displayed within this ComboBox.
class CoreComboBox<T, K> extends StatefulWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final List<T> options;
  final bool chevron;
  final bool underline;
  final Color valueColor;
  final ComboSizing sizing;
  final double popupWidth;
  final ChooseOption<T> change;
  final OptionToLabel<T> toLabel;
  final K Function(T value) toCoreValue;
  final T Function(K value) fromCoreValue;
  final bool typeahead;

  const CoreComboBox({
    @required this.objects,
    @required this.propertyKey,
    @required this.options,
    @required this.toCoreValue,
    @required this.fromCoreValue,
    this.chevron = true,
    this.underline = true,
    this.valueColor = Colors.white,
    this.sizing = ComboSizing.expanded,
    this.popupWidth,
    this.change,
    this.toLabel,
    this.typeahead = false,
    Key key,
  }) : super(key: key);

  @override
  _CoreComboBoxState<T, K> createState() => _CoreComboBoxState<T, K>();
}

class _CoreComboBoxState<T, K> extends State<CoreComboBox<T, K>> {
  @override
  Widget build(BuildContext context) {
    // return Container(color:Colors.red, height:10);
    return CorePropertiesBuilder(
      objects: widget.objects,
      propertyKey: widget.propertyKey,
      builder: (context, K value, _) => ComboBox(
        value: value == null ? null : widget.fromCoreValue(value),
        options: widget.options,
        chevron: widget.chevron,
        underline: widget.underline,
        valueColor: widget.valueColor,
        sizing: widget.sizing,
        popupWidth: widget.popupWidth,
        change: (T value) {
          if (widget.objects.isEmpty) {
            return;
          }

          dynamic coreValue = widget.toCoreValue(value);
          for (final object in widget.objects) {
            object.context
                .setObjectProperty(object, widget.propertyKey, coreValue);
          }
          widget.change?.call(value);

          widget.objects.first.context.captureJournalEntry();

          // Force focus back to the main context so that we can immediately
          // undo this change if we want to by hitting ctrl/comamnd z.
          RiveContext.find(context).focus();
        },
        toLabel: widget.toLabel,
        typeahead: widget.typeahead,
      ),
    );
  }
}
