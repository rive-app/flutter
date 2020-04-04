import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Manage a set of popup windows and close them when you click anywhere on the
/// screen outside the popups.
class Popup {
  OverlayEntry _entry;
  VoidCallback _onClose;
  bool _canAutoClose;

  void markNeedsBuild() => SchedulerBinding.instance
      .scheduleTask(_entry.markNeedsBuild, Priority.touch);

  @mustCallSuper
  bool close() {
    if (_entry == null) {
      return false;
    }
    _closeGuards.remove(this);
    _popups.remove(this);
    _entry.remove();
    if (_onClose != null) {
      // close can be called during build, so make sure we schedule the task so
      // it occurs after build.
      SchedulerBinding.instance.scheduleTask(_onClose, Priority.touch);
    }
    _entry = null;
    return true;
  }

  static final List<Popup> _popups = [];
  static final List<Popup> _closeGuards = [];

  Popup(
    OverlayEntry entry, {
    VoidCallback onClose,
    bool canAutoClose = true,
  })  : _entry = entry,
        _onClose = onClose,
        _canAutoClose = canAutoClose;

  static void closeAll({
    bool force = false,
  }) {
    // Copy the list so we don't modify it while closing.
    var close = _popups
        .where((popup) => popup._canAutoClose || force)
        .toList(growable: false);
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
    bool autoClose = true,
    bool includeCloseGuard = false,
  }) {
    OverlayState overlay = Overlay.of(context);

    if (_popups.isEmpty) {
      // place our catcher
      var popup = Popup(
        OverlayEntry(
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
        ),
      );
      _closeGuards.add(popup);
      _popups.add(popup);
      overlay.insert(popup._entry);
    }

    var popup = Popup(
      OverlayEntry(builder: builder),
      onClose: onClose,
      canAutoClose: autoClose,
    );
    if (includeCloseGuard && autoClose) {
      // place our own catch guard for this specific popup
      Popup guard;
      guard = Popup(
        OverlayEntry(
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
        ),
      );
      _closeGuards.add(popup);
      _popups.add(guard);
      overlay.insert(guard._entry);
    }

    _popups.add(popup);
    overlay.insert(popup._entry);
    return popup;
  }
}
