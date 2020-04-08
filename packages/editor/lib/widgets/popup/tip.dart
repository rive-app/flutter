import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/arrow_popup.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';

/// A widget that opens a tooltip when it is hovered.
class TipRegion extends StatefulWidget {
  final Tip tip;
  final Widget child;

  const TipRegion({
    @required this.tip,
    @required this.child,
    Key key,
  }) : super(key: key);

  @override
  _TipRegionState createState() => _TipRegionState();
}

class _TipRegionState extends State<TipRegion> {
  // Store the context so we don't have to look it up during dispose.
  TipContext _tipContext;
  @override
  void dispose() {
    _tipContext?.hide(widget.tip);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (_) {
        _tipContext = TipRoot.of(context);
        _tipContext.show(context, widget.tip);
      },
      onExit: (_) {
        _tipContext?.hide(widget.tip);
      },
      child: widget.child,
    );
  }
}

/// The data associated with a tooltip.
class Tip {
  // When we localize this could be a string key that gets looked up in some
  // language specific dictionary.
  final String label;

  /// When provided the item will display the key combination to trigger the
  /// shortcut.
  final ShortcutAction shortcut;

  /// The prioritized direction in which to show the tooltip. If this direction
  /// would result in an off-screen tooltip, the layout will pick one that
  /// works.
  final PopupDirection direction;

  /// Alternative directions used when the desired one would result in an
  /// off-screen layout.
  final List<PopupDirection> fallbackDirections;

  const Tip({
    this.label,
    this.shortcut,
    this.direction = PopupDirection.bottomToCenter,
    this.fallbackDirections = PopupDirection.all,
  });
}

class TipContext {
  final ValueNotifier<Tip> tooltip = ValueNotifier<Tip>(null);

  static const Duration delay = Duration(milliseconds: 400);

  BuildContext _nextContext;
  Tip _nextTip;
  ArrowPopup _currentPopup;
  Tip _currentTip;
  Timer _timer;
  int _suppressionCount = 0;

  /// Suppress showing the tooltips.
  void suppress() {
    _suppressionCount++;
  }

  // Allow showing the tooltips once suppression has been stabilized.
  bool encourage() {
    _suppressionCount--;

    assert(_suppressionCount >= 0);
    return _suppressionCount == 0;
  }

  /// Schedule showing this tooltip, note that it doesn't guarantee that the tip
  /// will be shown. It will show the tooltip after a delay, unless another one
  /// is already up in which case it'll replace the existing tooltip with the
  /// new one.
  void show(BuildContext context, Tip data) {
    if (_nextContext == context && _nextTip == data) {
      // already scheduled
      return;
    }
    _nextContext = context;
    _nextTip = data;

    if (_currentPopup != null) {
      // already showing the tooltip, just immediately replace it.
      _showNext();
    } else {
      // schedule it.
      _timer?.cancel();
      _timer = Timer(delay, _showNext);
    }
    // _nextTipRect = renderBox.localToGlobal(Offset.zero) & renderBox.size;
  }

  void hide(Tip data) {
    if (_nextTip == data) {
      _timer?.cancel();
      _timer = null;
      _nextTip = null;
      _nextContext = null;
    }
    if (_currentTip == data) {
      // Only set the hide timer if we're not already schedule to show another
      // tooltip.
      _timer ??= Timer(delay, _hideCurrent);
    }
  }

  void _hideCurrent() {
    _timer?.cancel();
    _timer = null;
    _currentPopup?.close();
    _currentPopup = null;
    _currentTip = null;
  }

  static Widget _buildTip(BuildContext context, Tip tip) {
    var theme = RiveTheme.of(context);
    var text = Text(tip.label, style: theme.textStyles.tooltipText);
    if (tip.shortcut != null) {
      return Row(
        children: [
          text,
          const SizedBox(width: 10),
          Text(
            ShortcutBindings.of(context)
                    ?.lookupKeysLabel(tip.shortcut)
                    ?.toUpperCase() ??
                "",
            style: theme.textStyles.popupShortcutText,
          ),
        ],
      );
    }
    return text;
  }

  void _showNext() {
    if (_nextTip == null) {
      return;
    }

    _hideCurrent();
    _currentTip = _nextTip;
    if (_suppressionCount == 0) {
      _currentPopup = ArrowPopup.show(
        _nextContext,

        // luigi: unconstrain the width, yikes seems like an anti-pattern, might
        // need to just make everything that wants to have a width specify
        // it...leaving it unaddressed for now.
        width: null,

        direction: _currentTip.direction,
        fallbackDirections: _currentTip.fallbackDirections,
        
        builder: (context) => Padding(
          padding: const EdgeInsets.all(15),
          child: _buildTip(context, _currentTip),
        ),
      );
    }

    _nextTip = null;
    _nextContext = null;
  }
}

/// The root of a tooltip widget hierarchy. This is necessary to manage which
/// tooltip is currently being shown, delay showing, hiding, and insuring only
/// one tip is visible at any given time.
class TipRoot extends InheritedWidget {
  final TipContext context;

  const TipRoot({
    this.context,
    Widget child,
    Key key,
  }) : super(key: key, child: child);

  static TipContext of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TipRoot>().context;
  }

  @override
  bool updateShouldNotify(TipRoot oldWidget) => oldWidget.context != context;
}
