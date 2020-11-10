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
  // hamburger menu
  'file_name': 'File Name',
  'revision_history': 'Revision History',
  'help_center': 'Help Center',
  'send_feedback': 'Send Feedback',

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
  'r': 'Rotation',
  'end': 'Gradient End',
  'start': 'Gradient Start',
  'start.startX': 'X',
  'start.startY': 'Y',
  'scale.sx': 'X',
  'scale.sy': 'Y',
  'bezier_in': 'In',
  'bezier_in.inRotation': 'Angle',
  'bezier_in.inDistance': 'Length',
  'bezier_out.outRotation': 'Angle',
  'bezier_out.outDistance': 'Length',
  'bezier_out': 'Out',
  'inDistance': 'In',
  'outDistance': 'Out',
  'colorValue': 'Color',
  'trimStart': 'Trim Start',
  'trimEnd': 'Trim End',
  'trimOffset': 'Trim Offset',
  'drawtargetid': 'Draw Rule',

  /// Used by the mirrored cubic vertex.
  'distance': 'Length',
  'in': 'In',
  'out': 'Out',
  'sx': 'X',
  'sy': 'Y',
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
  'select_key': 'Select a key',

  // Billing strings
  'normal': 'team',
  'premium': 'org',

  // Blend Modes,
  'srcOver': 'Normal',
  'darken': 'Darken',
  'multiply': 'Multiply',
  'colorBurn': 'Color Burn',
  'lighten': 'Lighten',
  'screen': 'Screen',
  'colorDodge': 'Color Dodge',
  'overlay': 'Overlay',
  'softLight': 'Soft Light',
  'hardLight': 'Hard Light',
  'difference': 'Difference',
  'exclusion': 'Exclusion',
  'hue': 'Hue',
  'saturation': 'Saturation',
  'color': 'Color',
  'luminosity': 'Luminosity',

  // Trim Paths
  'none': 'None',
  'sequential': 'Sequential',
  'synchronized': 'Synced',

  // Inspector Popout Titles
  'clip_options': 'Clip Options',
  'fill_options': 'Fill Options',
  'draw_order_rule': 'Draw Order Rule',
  'stroke_options': 'Stroke Options',

  'normal_draw_rule': 'Normal',
  'normal_draw_rule_desc':
      'This is the default draw order position based on Hierarchy.',
  'above_target': 'above target',
  'below_target': 'below target',
  'draw_order': 'Draw order',
  'target': 'Target',
  'select_drawable_target':
      'Select a drawable target (no groups) on the Stage or in the Hierarchy.'
});
