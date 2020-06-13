import 'dart:collection';
import 'package:logging/logging.dart';

import 'package:flutter/widgets.dart';

final _log = Logger('UIStrings');

/// Simple abstraction of String lookup with fallback value. Eventually can be
/// initialized with localized data. The map should probably deserialize from a
/// localized JSON file. Would be nice to retrieve these from the backend as
/// necessary and not bloat the app.
class UIStringsData {
  final HashMap<String, String> values;

  UIStringsData(this.values);

  String withKey(String key) {
    if (key == null) {
      return '???';
    }
    var value = values[key];
    if (value == null) {
      _log.warning('Missing UIString for key \'$key\'.');
      return key;
    }
    return value;
  }
}

class UIStrings extends InheritedWidget {
  const UIStrings({
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  UIStringsData get data => UIStringsData(_defaultUIStrings);

  static UIStringsData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UIStrings>().data;

  static UIStringsData find(BuildContext context) =>
      context.findAncestorWidgetOfExactType<UIStrings>().data;

  @override
  bool updateShouldNotify(UIStrings old) => data != old.data;
}

// Right now the keys pretty much map the values, but figured it'd be safer to
// have the abstraction in place.
HashMap<String, String> _defaultUIStrings =
    HashMap<String, String>.from(<String, String>{
  'position': 'Position',
  'radius': 'Corner',
  'scale': 'Scale',
  'opacity': 'Opacity',
  'x': 'X',
  'y': 'Y',
  'position.x': 'X',
  'position.y': 'Y',
  'end.endX': 'X',
  'end.endY': 'Y',
  'end': 'Gradient End',
  'start': 'Gradient Start',
  'start.startX': 'X',
  'start.startY': 'Y',
  'bezier_in': 'In',
  'bezier_in.inRotation': 'Angle',
  'bezier_in.inDistance': 'Length',
  'bezier_out.outRotation': 'Angle',
  'bezier_out.outDistance': 'Length',
  'bezier_out': 'Out',
  'inDistance': 'In',
  'outDistance': 'Out',
  'colorValue': 'Color',

  /// Used by the mirrored cubic vertex.
  'distance': 'Length',
  'in': 'In',
  'out': 'Out',
  'scaleX': 'X',
  'scaleY': 'Y',
  'vertices': 'Vertices',
  'thickness': 'Thickness',
  'strokes': 'Strokes',
  'hold': 'Hold',
  'linear': 'Linear',
  'drawOrder': 'Draw Order',
  'cubic': 'Cubic',
  'rotation': 'Rotation',
  'vertex-straight': 'Straight',
  'vertex-mirrored': 'Mirrored',
  'vertex-detached': 'Detached',
  'vertex-asymmetric': 'Asymmetric',
  // Billing strings
  'normal': 'team',
  'premium': 'org',
});
