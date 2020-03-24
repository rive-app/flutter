import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/tools/stage_tool.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/popup/tooltip_button.dart';
import 'package:rive_editor/widgets/rive_popup_button.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// Callback used to build the list of tool popup items.
typedef MakeToolPopupItems = List<PopupContextItem> Function(Rive);

/// Widget shared by the create and transform popup buttons to display a list of
/// stage tools and manage their selection. Abstracts some of the complexity
/// necessary to track whether an item from the set shown in the popup is the
/// currently selected item (and displays the appropriate icon in that case in
/// the button itself).
class ToolPopupButton extends StatefulWidget {
  final MakeToolPopupItems makeItems;
  final String defaultIcon;
  final double width;
  final Tip tip;
  final Widget Function(BuildContext, Rive, bool) iconBuilder;

  const ToolPopupButton({
    @required this.makeItems,
    this.defaultIcon,
    this.iconBuilder,
    this.width,
    this.tip,
    Key key,
  }) : super(key: key);

  @override
  _ToolPopupButtonState createState() => _ToolPopupButtonState();
}

class _ToolPopupButtonState extends State<ToolPopupButton> {
  // Timer to close the popup
  ListPopup<PopupContextItem> _popup;
  Timer _closeTimer;

  @override
  Widget build(BuildContext context) {
    var rive = RiveContext.of(context);
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
          tip: widget.tip,
          width: widget.width,
          opened: (popup) {
            _popup = popup;
          },
          contextItems: items,
          iconBuilder: widget.iconBuilder ??
              (context, rive, isHovered) {
                var item = PopupContextItem.withIcon(tool.icon, items);

                var icon = TintedIcon(
                  color: item != null
                      ? RiveTheme.of(context).colors.toolbarButtonSelected
                      : isHovered
                          ? RiveTheme.of(context).colors.toolbarButtonHover
                          : RiveTheme.of(context).colors.toolbarButton,
                  icon: item != null ? tool.icon : widget.defaultIcon,
                );

                if (item != null) {
                  // if we have an active icon, let's show the tooltip with the
                  // info about the active icon.
                  return TipRegion(
                      tip: Tip(
                        label: item.name,
                        shortcut: item.shortcut,
                      ),
                      child: icon);
                } else {
                  return icon;
                }
              },
        );
      },
    );
  }
}
