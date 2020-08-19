import 'package:flutter/material.dart';
import 'package:rive_core/component.dart';
import 'package:rive_editor/widgets/inspector/properties/property_item.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_popout.dart';

/// A row in the inspector representing some Core [Component]. It presents an
/// options popout that can be customized by the implementation (currently not
/// implemented). Also has the option of renaming, removing, and toggling the
/// visibility of the component.
class InspectorPopoutComponent extends StatelessWidget {
  final Iterable<Component> components;
  final int isVisiblePropertyKey;
  final WidgetBuilder prefix;
  final WidgetBuilder popoutBuilder;
  final PopupCallback opened;
  final PopupCallback closed;

  const InspectorPopoutComponent({
    @required this.components,
    this.isVisiblePropertyKey,
    this.prefix,
    this.popoutBuilder,
    this.opened,
    this.closed,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorPopout(
      opened: opened,
      closed: closed,
      contentBuilder: (_) => PropertyItem(
        components: components,
        prefix: prefix,
        isVisiblePropertyKey: isVisiblePropertyKey,
      ),
      popupBuilder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: popoutBuilder(context),
      ),
    );
  }
}
