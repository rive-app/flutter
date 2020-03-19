import 'package:core/debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_core/component.dart';
import 'package:core/core.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/transform_space.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
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
  static const Color defaultGradientColorA = Color(0xFFFF5678);
  static const Color defaultGradientColorB = Color(0xFFD041AB);

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

  void changeType(ColorType colorType) {
    if (type.value == colorType) {
      return;
    }

    var file = context;

    // Batch the operation so that we can pick apart the hierarchy and then
    // resolve once we're done changing everything.
    file.batchAdd(() {
      for (final paint in shapePaints) {
        var mutator = paint.paintMutator as Component;
        var shape = paint.paintMutator.shape;
        // Remove the old paint mutator (this is what a color component is
        // referenced as in the fill/stroke).
        if (mutator is ContainerComponent) {
          // If it's a container (like a gradient which contains color stops)
          // make sure to remove everything.
          mutator.removeRecursive();
        } else {
          mutator.remove();
        }
        switch (colorType) {
          case ColorType.solid:
            var solidColor = SolidColor();
            file.add(solidColor);
            paint.appendChild(solidColor);
            break;
          case ColorType.linear:
            // Compute the shapes bounds to place the gradient start/end in.
            var bounds = shape.computeBounds(TransformSpace.local);
            var linearGradient = core.LinearGradient()
              ..startX = bounds.left
              ..startY = bounds.centerLeft.dy
              ..endX = bounds.right
              ..endY = bounds.centerLeft.dy;

            // Add two stops.
            var gradientStopA = GradientStop()
              ..color = defaultGradientColorA
              ..position = 0;
            var gradientStopB = GradientStop()
              ..color = defaultGradientColorB
              ..position = 1;

            file.add(linearGradient);
            file.add(gradientStopA);
            file.add(gradientStopB);
            paint.appendChild(linearGradient);
            linearGradient.appendChild(gradientStopA);
            linearGradient.appendChild(gradientStopB);

            editingIndex.value = 0;
            break;
          case ColorType.radial:
            // Compute the shapes bounds to place the gradient start/end in.
            var bounds = shape.computeBounds(TransformSpace.local);
            var radialGradient = core.RadialGradient()
              ..startX = bounds.left
              ..startY = bounds.centerLeft.dy
              ..endX = bounds.right
              ..endY = bounds.centerLeft.dy;

            // Add two stops.
            var gradientStopA = GradientStop()
              ..color = defaultGradientColorA
              ..position = 0;
            var gradientStopB = GradientStop()
              ..color = defaultGradientColorB
              ..position = 1;

            file.add(radialGradient);
            file.add(gradientStopA);
            file.add(gradientStopB);
            paint.appendChild(radialGradient);
            radialGradient.appendChild(gradientStopA);
            radialGradient.appendChild(gradientStopB);

            editingIndex.value = 0;
            break;
        }
      }
    });

    // Hierarchy has now resolved, new mutators have been assined to shapePaints
    // (fills/strokes).

    _updatePaints();

    completeChange();
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

  RiveFile get context => shapePaints.first.context;

  void completeChange() {
    context?.captureJournalEntry();
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

  ColorType _determineColorType() =>
      equalValue<ShapePaint, ColorType>(shapePaints, (shapePaint) {
        // determine which concrete color type this shapePaint is using.
        var colorComponent = shapePaint.paintMutator as Component;
        if (colorComponent == null) {
          return null;
        }
        switch (colorComponent.coreType) {
          case SolidColorBase.typeKey:
            return ColorType.solid;
          case core.LinearGradientBase.typeKey:
            return ColorType.linear;
          case core.RadialGradientBase.typeKey:
            return ColorType.radial;
        }
        return null;
      });

  /// Update current color type and state, also register (and cleanup) listeners
  /// for changes due to undo/redo.
  void _updatePaints({bool forceRelisten = false}) {
    // Are we all the same type?
    var colorType = _determineColorType();
    var relisten = type.value != colorType || forceRelisten;
    if (relisten) {
      // clear out old listeners
      _listeningTo.forEach((component, value) {
        for (final propertyKey in value) {
          component.removeListener(propertyKey, _valueChanged);
        }
      });
    }

    var first = shapePaints.first.paintMutator;
    switch (colorType) {
      case ColorType.solid:
        // If the full list is solid then we definitely have a SolidColor
        // mutator.
        editingColor.value = HSVColor.fromColor((first as SolidColor).color);

        if (preview.value.length != 1 ||
            preview.value.first != editingColor.value.toColor()) {
          // check all colors are the same
          Color color = equalValue<ShapePaint, Color>(shapePaints,
              (shapePaint) => (shapePaint.paintMutator as SolidColor).color);
          preview.value = color == null ? [] : [color];
        }

        if (relisten) {
          // Since they're all solid, we know they'll all have a Core colorValue
          // that change that we want to listen to.
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
