import 'package:flutter/material.dart';
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

  const InspectorPopout({
    @required this.contentBuilder,
    @required this.popupBuilder,
    this.opened,
    this.closed,
    Key key,
  }) : super(key: key);
  @override
  _InspectorPopoutState createState() => _InspectorPopoutState();

  static Popup popout(
    BuildContext context, {
    double width = 234,
    VoidCallback onClose,
    WidgetBuilder builder,
  }) {
    var theme = RiveTheme.of(context);

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    return Popup.show(
      context,
      onClose: onClose,
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
                borderRadius: BorderRadius.circular(5.0),
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

  /* var theme = RiveTheme.of(context);

    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    var popoutWidth = widget.popoutWidth;
    var left = boxOffset.dx - popoutWidth - _popoutToPanelOffset;
    var top = boxOffset.dy;
    var media = MediaQuery.of(context);

    var availableHeight = media.size.height - top - _screenEdgeMargin;
    if (widget.popupHeight != null) {
      if (availableHeight < widget.popupHeight) {
        top -= widget.popupHeight - availableHeight;
      }
    } else if (availableHeight < widget.minPopupHeight) {
      top -= widget.minPopupHeight - availableHeight;
    }

    var popup = Popup.show(
      context,
      onClose: () {
        setState(() {
          _popup = null;
        });
      },
      builder: (context) {
        return InspectorPopoutPositioner(
          right: right,
          top: top,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colors.panelBackgroundDarkGrey,
                borderRadius: BorderRadius.circular(5.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.40),
                    offset: const Offset(0, 50),
                    blurRadius: 100,
                  )
                ],
              ),
              // height: 300,
              child: widget.popupBuilder(context),
            ),
          ),
        );
      },
    );

    setState(() {
      _popup = popup;
    });
  }
*/
  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Padding(
      // TODO: Top padding might need tweaking here, depends on how this widget
      // is grouped into the inspector. Note that left padding is 15 as the
      // popout button has a padding of 5, bringing the total left padding to
      // 20. This is so the icon aligns at 20 but the hit area of the button
      //     starts at 15.
      padding: const EdgeInsets.only(top: 5, bottom: 5, left: 15, right: 20),
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
                      icon: 'options',
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
