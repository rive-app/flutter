import 'package:flutter/widgets.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

class PropertyItem extends StatelessWidget {
  final Iterable<Component> components;
  final int isVisiblePropertyKey;
  final WidgetBuilder prefix;
  final WidgetBuilder postfix;

  const PropertyItem({
    Key key,
    this.components,
    this.isVisiblePropertyKey,
    this.prefix,
    this.postfix,
  }) : super(key: key);

  void _rename(String name) {
    for (final object in components) {
      object.context
          .setObjectProperty(object, ComponentBase.namePropertyKey, name);
    }
    components.first.context.captureJournalEntry();
  }

  void _remove() {
    for (final component in components) {
      if (component is ContainerComponent) {
        component.removeRecursive();
      } else {
        component.remove();
      }
    }
    components.first.context.captureJournalEntry();
  }

  void _toggleVisibility(bool isVisible) {
    for (final object in components) {
      object.context.setObjectProperty(object, isVisiblePropertyKey, isVisible);
    }
    components.first.context.captureJournalEntry();
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Row(
      children: [
        if (prefix != null) prefix(context),
        Expanded(
          child: CorePropertiesBuilder(
            objects: components,
            propertyKey: ComponentBase.namePropertyKey,
            builder: (context, String name, _) {
              return Renamable(
                color: lightGrey,
                editingColor: theme.colors.activeText,
                name: name,
                onRename: _rename,
              );
            },
          ),
        ),
        if (postfix != null) postfix(context),
        if (isVisiblePropertyKey != null)
          CorePropertiesBuilder(
            objects: components,
            propertyKey: isVisiblePropertyKey,
            builder: (context, bool isVisible, _) => TintedIconButton(
              onPress: () => _toggleVisibility(!(isVisible ?? true)),
              icon:
                  isVisible ?? true ? PackedIcon.visibility : PackedIcon.hidden,
            ),
          ),
        TintedIconButton(
          onPress: _remove,
          icon: PackedIcon.delete,
        ),
      ],
    );
  }
}
