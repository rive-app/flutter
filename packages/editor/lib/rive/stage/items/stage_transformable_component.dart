import 'package:flutter/foundation.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/transform_component.dart';
import 'package:rive_editor/rive/stage/items/stage_transformable.dart';

abstract class StageTransformableComponent<T extends TransformComponent>
    implements StageTransformable {
  T get component;

  @override
  Mat2D get renderTransform =>
      component.artboard.transform(component.worldTransform);

  @override
  Mat2D get worldTransform => component.worldTransform;

  @override
  Listenable get worldTransformChanged => component.worldTransformChanged;
}
