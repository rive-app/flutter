import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Manage a set of popup windows and close them when you click anywhere on the
/// screen outside the popups.
class Popup {
  OverlayEntry _entry;
  VoidCallback _onClose;

  @mustCallSuper
  bool close() {
    if (_entry == null) {
      return false;
    }
    _closeGuards.remove(this);
    _popups.remove(this);
    _entry.remove();
    _onClose?.call();
    _entry = null;
    return true;
  }

  static final List<Popup> _popups = [];
  static final List<Popup> _closeGuards = [];

  Popup(OverlayEntry entry, {VoidCallback onClose})
      : _entry = entry,
        _onClose = onClose;

  static void closeAll() {
    // Copy the list so we don't modify it while closing.
    var close = _popups.toList(growable: false);
    _popups.clear();

    for (final popup in close) {
      popup.close();
    }
  }

  static bool isOpen(Popup entry) => _popups.contains(entry);

  static bool remove(Popup popup) {
    if (_popups.remove(popup)) {
      popup.close();
      return true;
    }
    return false;
  }

  factory Popup.show(
    BuildContext context, {
    @required WidgetBuilder builder,
    VoidCallback onClose,
    bool includeCloseGuard = false,
  }) {
    OverlayState overlay = Overlay.of(context);

    if (_popups.isEmpty) {
      // place our catcher
      var popup = Popup(OverlayEntry(
        builder: (context) {
          return Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (details) {
                if (_closeGuards.length == 1) {
                  // We're the only guard up.
                  closeAll();
                }
              },
            ),
          );
        },
      ));
      _closeGuards.add(popup);
      _popups.add(popup);
      overlay.insert(popup._entry);
    }

    var popup = Popup(OverlayEntry(builder: builder), onClose: onClose);
    if (includeCloseGuard) {
      // place our own catch guard for this specific popup
      Popup guard;
      guard = Popup(OverlayEntry(
        builder: (context) {
          return Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (details) {
                SchedulerBinding.instance.scheduleTask(() {
                  popup.close();
                  guard.close();
                }, Priority.touch);
              },
            ),
          );
        },
      ));
      _closeGuards.add(popup);
      _popups.add(guard);
      overlay.insert(guard._entry);
    }

    _popups.add(popup);
    overlay.insert(popup._entry);
    return popup;
  }
}
