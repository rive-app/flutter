import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Manage a set of popup windows and close them when you click anywhere on the
/// screen outside the popups.
class Popup {
  OverlayEntry _entry;
  VoidCallback _onClose;
  final Future<bool> Function() shouldClose;
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

  static int get openLength => _popups.length;

  Popup(
    OverlayEntry entry, {
    VoidCallback onClose,
    bool canAutoClose = true,
    this.shouldClose,
  })  : _entry = entry,
        _onClose = onClose,
        _canAutoClose = canAutoClose;

  static Future<void> closeAll({
    bool force = false,
    Set<Popup> exclude,
  }) async {
    // Copy the list so we don't modify it while closing.
    Set<Popup> close = {};
    for (final popup in _popups) {
      if (force ||
          (popup._canAutoClose &&
              (popup.shouldClose == null || await popup.shouldClose()))) {
        close.add(popup);
      }
    }

    if (exclude != null) {
      close = close.difference(exclude);
    }
    _popups.removeWhere((popup) => close.contains(popup));
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
    Future<bool> Function() shouldClose,
  }) {
    OverlayState overlay = Overlay.of(context);

    if (_popups.isEmpty) {
      // place our catcher
      Popup firstGuard;
      firstGuard = Popup(
        OverlayEntry(
          builder: (context) {
            return Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (details) async {
                  if (_closeGuards.length == 1) {
                    // We're the only guard up.
                    await closeAll(exclude: {firstGuard});
                    // if everything else closed, we can take this guard down
                    if (Popup.openLength == 1) {
                      firstGuard.close();
                    }
                  }
                },
              ),
            );
          },
        ),
      );
      _closeGuards.add(firstGuard);
      _popups.add(firstGuard);
      overlay.insert(firstGuard._entry);
    }

    var popup = Popup(
      OverlayEntry(builder: builder),
      onClose: onClose,
      canAutoClose: autoClose,
      shouldClose: shouldClose,
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
                  SchedulerBinding.instance.scheduleTask(() async {
                    if (popup.shouldClose == null ||
                        await popup.shouldClose()) {
                      popup.close();
                      guard.close();
                    }
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
