import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/editor_switch.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';

/// A toggle (on/off) switch with styling for the Rive editor with bindings to a
/// core property which is expected to be of bool type.
class CoreEditorSwitch extends StatelessWidget {
  final Iterable<Core> objects;
  final int propertyKey;

  const CoreEditorSwitch({
    @required this.objects,
    @required this.propertyKey,
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CorePropertiesBuilder(
      objects: objects,
      propertyKey: propertyKey,
      builder: (context, bool value, _) => EditorSwitch(
        isOn: value,
        toggle: () {
          if (objects.isEmpty) {
            return;
          }

          bool coreValue;
          if (value == null) {
            coreValue = true;
          } else {
            coreValue = !value;
          }
          for (final object in objects) {
            object.context.setObjectProperty(object, propertyKey, coreValue);
          }

          objects.first.context.captureJournalEntry();
        },
      ),
    );
  }
}
