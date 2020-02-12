import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Callback used to build the list of tool popup items.
typedef MakeToolPopupItems = List<PopupContextItem<Rive>> Function(Rive);

/// Widget shared by the create and transform popup buttons to display a list of
/// stage tools and manage their selection. Abstracts some of the complexity
/// necessary to track whether an item from the set shown in the popup is the
/// currently selected item (and displays the appropriate icon in that case in
/// the button itself).
class ToolPopupButton extends StatefulWidget {
  final MakeToolPopupItems makeItems;
  final String defaultIcon;

  const ToolPopupButton({
    @required this.makeItems,
    @required this.defaultIcon,
    Key key,
  }) : super(key: key);

  @override
  _ToolPopupButtonState createState() => _ToolPopupButtonState();
}

class _ToolPopupButtonState extends State<ToolPopupButton> {
  // Timer to close the popup
  ListPopup<Rive, PopupContextItem<Rive>> _popup;
  Timer _closeTimer;

  @override
  Widget build(BuildContext context) {
    var rive = Provider.of<Rive>(context);
    return ValueListenableBuilder<StageTool>(
      valueListenable: rive.stage.value.toolNotifier,
      builder: (context, tool, _) {
        // If the popup is open during a selection, close it, but debounce it so
        // the user has the opportunity to catch a flash of the change.
        if (_popup?.isOpen ?? false) {
          _closeTimer?.cancel();
          _closeTimer = Timer(const Duration(milliseconds: 100), () {
            _popup?.close();
          });
        }
        var items = widget.makeItems(rive);
        return RivePopupButton(
          opened: (popup) {
            _popup = popup;
          },
          contextItems: items,
          iconBuilder: (context, rive, isHovered) {
            bool hasActiveIcon = PopupContextItem.hasIcon(tool.icon, items);

            return TintedIcon(
              color: hasActiveIcon
                  ? const Color(0xFF57A5E0)
                  : isHovered
                      ? Colors.white
                      : const Color.fromRGBO(140, 140, 140, 1),
              icon: PopupContextItem.hasIcon(tool.icon, items)
                  ? tool.icon
                  : widget.defaultIcon,
            );
          },
        );
      },
    );
  }
}
