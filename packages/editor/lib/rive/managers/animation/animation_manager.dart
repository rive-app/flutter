import 'package:rive_core/animation/linear_animation.dart';

/// Base class for animation managers.
abstract class AnimationManager {
  final LinearAnimation animation;
  AnimationManager(this.animation);
}