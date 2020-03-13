import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/rive/theme.dart';
import 'package:rive_editor/widgets/common/renamable.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/core_properties_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout.dart';

class InspectorPopoutComponent extends StatelessWidget {
  final Iterable<Component> components;
  final int isVisiblePropertyKey;
  final WidgetBuilder prefix;

  const InspectorPopoutComponent({
    @required this.components,
    this.isVisiblePropertyKey,
    this.prefix,
    Key key,
  }) : super(key: key);

  void _rename(String name) {
    for (final object in components) {
      object.context
          .setObjectProperty(object, ComponentBase.namePropertyKey, name);
    }
    components.first.context.captureJournalEntry();
  }

  void _remove() {
    var coreContext = components.first.context;
    components.forEach(coreContext.remove);
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
    return InspectorPopout(
      contentBuilder: (context) => Row(
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
          if (isVisiblePropertyKey != null)
            CorePropertiesBuilder(
              objects: components,
              propertyKey: isVisiblePropertyKey,
              builder: (context, bool isVisible, _) => TintedIconButton(
                onPress: () => _toggleVisibility(!(isVisible ?? true)),
                icon: isVisible ?? true ? 'visibility' : 'hidden',
              ),
            ),
          TintedIconButton(
            onPress: _remove,
            icon: 'delete',
          ),
        ],
      ),
      popupBuilder: (context) => Container(
        height: 100,
        child: const Text('Popup Builder'),
      ),
    );
  }
}
