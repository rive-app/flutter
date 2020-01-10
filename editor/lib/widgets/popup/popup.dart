import 'package:flutter/material.dart';

/// Manage a set of popup windows and close them when you click anywhere on the
/// screen outside the popups.
class Popup {
  static List<OverlayEntry> _entries = [];
  static void closeAll() {
    for (final entry in _entries) {
      entry.remove();
    }
    _entries.clear();
  }

  static OverlayEntry show(BuildContext context,
      {@required WidgetBuilder builder, double width = 177}) {
    OverlayState overlay = Overlay.of(context);

    if (_entries.isEmpty) {
      // place our catcher
      var entry = OverlayEntry(
        builder: (context) {
          return Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (details) {
                closeAll();
              },
            ),
          );
        },
      );
      _entries.add(entry);
      overlay.insert(entry);
    }

    var entry = OverlayEntry(builder: builder);
    _entries.add(entry);
    overlay.insert(entry);
    return entry;
  }
}
