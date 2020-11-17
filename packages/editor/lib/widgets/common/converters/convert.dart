import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/shapes/paint/trim_path.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_core/shapes/cubic_asymmetric_vertex.dart';
import 'package:rive_core/shapes/cubic_detached_vertex.dart';
import 'package:rive_core/shapes/cubic_mirrored_vertex.dart';
import 'package:rive_core/shapes/paint/gradient_stop.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/percentage_input_converter.dart';
import 'package:rive_editor/widgets/common/converters/rotation_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/scale_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/translation_value_converter.dart';

/// Get the right converter for the backing property key. This should be used in
/// both the inspector and the timeline.
InputValueConverter<T> converterForProperty<T>(int propertyKey) {
  switch (propertyKey) {
    case GradientStopBase.positionPropertyKey:
    case LinearGradientBase.opacityPropertyKey:
    case TransformComponentBase.opacityPropertyKey:
    case TrimPathBase.startPropertyKey:
    case TrimPathBase.endPropertyKey:
      return ClampedPercentageInputConverter.instance as InputValueConverter<T>;
    case TransformComponentBase.rotationPropertyKey:
    case CubicAsymmetricVertexBase.rotationPropertyKey:
    case CubicDetachedVertexBase.inRotationPropertyKey:
    case CubicDetachedVertexBase.outRotationPropertyKey:
    case CubicMirroredVertexBase.rotationPropertyKey:
      return RotationValueConverter.instance as InputValueConverter<T>;
    case ArtboardBase.xPropertyKey:
    case ArtboardBase.yPropertyKey:
    case NodeBase.xPropertyKey:
    case NodeBase.yPropertyKey:
      return TranslationValueConverter.instance as InputValueConverter<T>;

    case ArtboardBase.originXPropertyKey:
    case ArtboardBase.originYPropertyKey:
    case ParametricPathBase.originXPropertyKey:
    case ParametricPathBase.originYPropertyKey:
    case TrimPathBase.offsetPropertyKey:
    case TransformComponentBase.scaleXPropertyKey:
    case TransformComponentBase.scaleYPropertyKey:
      return ScalePercentageValueConverter.instance as InputValueConverter<T>;

    default:
      return TranslationValueConverter.instance as InputValueConverter<T>;
  }
}
