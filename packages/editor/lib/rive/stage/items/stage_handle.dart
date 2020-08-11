import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/transformers/stage_transformer.dart';

import 'package:meta/meta.dart';

/// A handle the user can interact with that usually causes some form of
/// transformation on the selected objects.
abstract class StageHandle extends StageItem<void> {
  /// The transform in backboard space
  final Mat2D _renderTransform = Mat2D();
  Mat2D get renderTransform => _renderTransform;

  /// The transform in world (artboard) space.
  final Mat2D _transform = Mat2D();
  Mat2D get transform => _transform;

  @override
  bool get isSelectable => false;

  @override
  bool get isHoverSelectable => isVisible;

  Vec2D get translation => Mat2D.getTranslation(_transform, Vec2D());
  Vec2D get renderTranslation =>
      Mat2D.getTranslation(_renderTransform, Vec2D());

  @nonVirtual
  void setTransform(Mat2D transform, Mat2D renderTransform) {
    if (Mat2D.areEqual(transform, _transform) &&
        Mat2D.areEqual(renderTransform, _renderTransform)) {
      return;
    }

    Mat2D.copy(_transform, transform);
    Mat2D.copy(_renderTransform, renderTransform);

    transformChanged();
  }

  List<StageTransformer> makeTransformers();
  void transformChanged();

  /// Return the TransformFlags that matches this transform handle.
  int get transformType;
}
