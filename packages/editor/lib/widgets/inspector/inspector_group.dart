import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';

/// An expandable group row in the InspectorPanel. Doesn't actually contain the
/// items it expands as they get inserted by a builder into the full
/// InspectorPanel's ListView. This allows the InspectorPanel to have a
/// predictable ListView height which improves virtualization and scrolling.
class InspectorGroup extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback tapExpand;
  final VoidCallback add;
  final String name;

  const InspectorGroup({
    Key key,
    this.isExpanded,
    this.tapExpand,
    this.add,
    this.name,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTapDown: (_) {
              tapExpand();
            },
            child: Container(
              width: 15,
              height: 15,
              // color: Colors.green,
              child: Container(
                child: Center(
                  child: TreeExpander(
                    iconColor: Colors.white,
                    isExpanded: isExpanded,
                  ),
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade700,
                    width: 1.0,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(7.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              name.toUpperCase(),
              style: RiveTheme.of(context).textStyles.inspectorSectionHeader,
            ),
          ),
          add == null
              ? Container()
              : TintedIconButton(
                  onPress: add,
                  icon: 'add',
                ),
        ],
      ),
    );
  }
}
