import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/popup_positioner.dart';
import 'package:rive_editor/widgets/popup/base_popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

/// How much space to put between the popup and the left side of the inspector
/// panel row.
const double _popoutToPanelOffset = 10;

typedef PopupCallback = void Function(Popup);

/// A wrapper widget for an inspector row that contains a popout/overflow menu
/// triggered by clicking on the options icon. The [contentBuilder] builds the
/// rest of the inspector row while the popup builder gets called to populate
/// the popup when it is opened.
///
/// ![](https://assets.rvcd.in/inspector/property_popout/content_builder.png)
/// ![](https://assets.rvcd.in/inspector/property_popout/popup_builder.png)
class InspectorPopout extends StatefulWidget {
  /// Builder for the remaining horizontal space next to the options button.
  final WidgetBuilder contentBuilder;

  /// Builder for the contents of the popup shown when the options button is
  /// pressed.
  final WidgetBuilder popupBuilder;

  /// Called when the popup is opened.
  final PopupCallback opened;

  /// Called when the popup is closed.
  final PopupCallback closed;

  /// Custom padding to put around the entire row.
  final EdgeInsets padding;

  // Note that left padding is 15 as the popout button has a padding of 5,
  // bringing the total left padding to 20. This is so the icon aligns at 20 but
  // the hit area of the button starts at 15.
  static const defaultPadding =
      EdgeInsets.only(top: 8, bottom: 10, left: 15, right: 15);

  const InspectorPopout({
    @required this.contentBuilder,
    @required this.popupBuilder,
    this.opened,
    this.closed,
    this.padding,
    Key key,
  }) : super(key: key);
  @override
  _InspectorPopoutState createState() => _InspectorPopoutState();

  static Popup popout(
    BuildContext context, {
    double width = 234,
    VoidCallback onClose,
    WidgetBuilder builder,
    Future<bool> Function() shouldClose,
    bool autoClose = true,
  }) {
    var theme = RiveTheme.of(context);

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    // close all other popups when we're opening a new 'main' popup.
    Popup.closeAll(force: true);
    return Popup.show(
      context,
      onClose: onClose,
      autoClose: autoClose,
      shouldClose: shouldClose,
      canCancelWithAction: true,
      builder: (context) {
        return InspectorPopoutPositioner(
          top: boxOffset.dy,
          right: renderBox.size.width + _popoutToPanelOffset,
          width: width,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.panelBackgroundDarkGrey,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.40),
                    offset: const Offset(0, 50),
                    blurRadius: 100,
                  )
                ],
              ),
              // height: size.height,
              child: builder(context),
            ),
          ),
        );
      },
    );
  }
}

class _InspectorPopoutState extends State<InspectorPopout> {
  bool _isHovered = false;
  Popup _popup;

  @override
  void dispose() {
    super.dispose();
    _popup?.close();
  }

  void _showPopup(BuildContext context) {
    var popup = InspectorPopout.popout(
      context,
      onClose: () {
        if (!mounted) {
          return;
        }
        setState(() {
          widget.closed?.call(_popup);
          _popup = null;
        });
      },
      builder: widget.popupBuilder,
    );
    widget.opened?.call(popup);

    setState(() {
      _popup = popup;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Padding(
      padding: widget.padding ?? InspectorPopout.defaultPadding,
      child: Row(
        children: [
          IgnorePointer(
            ignoring: _popup != null,
            child: GestureDetector(
              onTapDown: (_) => _showPopup(context),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _popup != null
                        ? theme.colors.toolbarButtonBackGroundPressed
                        : _isHovered
                            ? theme.colors.toolbarButtonBackGroundHover
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: TintedIcon(
                      color: _isHovered || _popup != null
                          ? theme.colors.toolbarButtonHover
                          : theme.colors.toolbarButton,
                      icon: PackedIcon.options,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: widget.contentBuilder(context),
          )
        ],
      ),
    );
  }
}
