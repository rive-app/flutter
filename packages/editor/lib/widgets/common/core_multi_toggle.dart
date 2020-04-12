import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/multi_toggle.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// A multi toggle that displays icons in a row for each option backed by a core
/// value.
class CoreMultiToggle<T, K> extends StatelessWidget {
  final Iterable<Core> objects;
  final int propertyKey;
  final List<T> options;
  final OptionToIcon<T> toIcon;
  final K Function(T value) toCoreValue;
  final T Function(K value) fromCoreValue;

  const CoreMultiToggle({
    @required this.objects,
    @required this.propertyKey,
    @required this.options,
    @required this.toCoreValue,
    @required this.fromCoreValue,
    @required this.toIcon,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      objects: objects,
      propertyKey: propertyKey,
      builder: (context, K value, _) => MultiToggle(
        options: options,
        value: value == null ? null : fromCoreValue(value),
        toIcon: toIcon,
        change: (T option) {
          print("CHANGE $option");
          if (objects.isEmpty) {
            return;
          }

          dynamic coreValue = toCoreValue(option);
          for (final object in objects) {
            object.context.setObjectProperty(object, propertyKey, coreValue);
          }

          objects.first.context.captureJournalEntry();

          // Force focus back to the main context so that we can immediately
          // undo this change if we want to by hitting ctrl/comamnd z.
          RiveContext.find(context).focus();
        },
      ),
    );
  }
}
