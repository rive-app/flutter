import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:core/core.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_core/shapes/paint/shape_paint.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';

/// Color change callback used by the various color picker components.
typedef ChangeColor = void Function(HSVColor);

/// Abstraction of the currently inspected color.
class InspectingColor {
  static const Color defaultSolidColor = Color(0xFF747474);
  ValueNotifier<ColorType> type = ValueNotifier<ColorType>(null);
  ValueNotifier<List<Color>> preview = ValueNotifier<List<Color>>([]);
  ValueNotifier<int> editingIndex = ValueNotifier<int>(0);
  ValueNotifier<HSVColor> editingColor =
      ValueNotifier<HSVColor>(HSVColor.fromColor(const Color(0xFFFF0000)));

  /// Track which properties we're listening to on each component. This varies
  /// depending on whether it's a solid color, gradient, etc.
  final Map<Component, Set<int>> _listeningTo = {};

  /// Whether we should perform an update in response to a core value change.
  /// This allows us to not re-process updates as we're interactively changing
  /// values from this inspector.
  bool _suppressUpdating = false;

  Iterable<ShapePaint> shapePaints;
  InspectingColor(this.shapePaints) {
    _updatePaints();
  }

  /// Change the currently editing color
  void changeColor(HSVColor color) {
    editingColor.value = color;
    switch (type.value) {
      case ColorType.solid:
        _changeSolidColor(color.toColor());
        break;
      default:
        break;
    }
  }

  void completeChange() {
    shapePaints.first.context?.captureJournalEntry();
  }

  void dispose() {}

  void _changeSolidColor(Color color) {
    _suppressUpdating = true;

    // Track whether or not we added new core objects.
    bool added = false;
    var context = shapePaints.first.context;
    // Do the change in a batch add as it can create new core objects.
    // context.batchAdd(() {

    // make sure we have SolidColors, make them if we don't and delete
    // existing mutators.
    for (final paint in shapePaints) {
      SolidColor solid;
      if (paint.paintMutator is SolidColor) {
        solid = paint.paintMutator as SolidColor;
      } else {
        if (paint.paintMutator != null) {
          /// Remove the old color.
          context.remove(paint.paintMutator as Component);
        }
        added = true;
        solid = SolidColor();
        context.add(solid);
        paint.appendChild(solid);
      }
      solid.color = color;
    }

    _suppressUpdating = false;

    if (added) {
      // Re-build the listeners if we added objects.
      _updatePaints(forceRelisten: true);
    }
    // Force update the preview.
    preview.value = [editingColor.value.toColor()];

    // });
  }

  void _listenTo(Component component, int propertyKey) {
    if (component.addListener(propertyKey, _valueChanged)) {
      var keySet = _listeningTo[component] ??= {};
      keySet.add(propertyKey);
    }
  }

  /// Update current color type and state, also register (and cleanup) listeners
  /// for changes due to undo/redo.
  void _updatePaints({bool forceRelisten = false}) {
    var first = shapePaints.first.paintMutator;

    ColorType colorType = first is core.LinearGradient
        ? ColorType.linear
        : first is core.RadialGradient ? ColorType.radial : ColorType.solid;

    var relisten = type.value != colorType || forceRelisten;
    if (relisten) {
      // clear out old listeners
      _listeningTo.forEach((component, value) {
        for (final propertyKey in value) {
          component.removeListener(propertyKey, _valueChanged);
        }
      });
    }

    switch (colorType) {
      case ColorType.solid:
        // Cold still be null...
        if (first is SolidColor) {
          editingColor.value = HSVColor.fromColor(first.color);
        } else {
          editingColor.value = HSVColor.fromColor(defaultSolidColor);
        }
        if (preview.value.length != 1 ||
            preview.value.first != editingColor.value.toColor()) {
          // check all colors are the same
          Color color = equalValue<ShapePaint, Color>(shapePaints,
              (shapePaint) => (shapePaint.paintMutator as SolidColor).color);
          preview.value = color == null ? [] : [color];
        }

        if (relisten) {
          for (final shapePaint in shapePaints) {
            _listenTo(shapePaint.paintMutator as Component,
                SolidColorBase.colorValuePropertyKey);
          }
        }
        break;
      case ColorType.linear:
        break;
      case ColorType.radial:
        break;
    }
    type.value = colorType;
  }

  void _valueChanged(dynamic from, dynamic to) {
    if (_suppressUpdating) {
      return;
    }
    debounce(_updatePaints);
  }
}
