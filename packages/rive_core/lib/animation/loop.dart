/// Loop options for linear animations.
enum Loop {
  /// Play until the duration of the animation.
  oneShot,

  /// Play until the duration of the animation and then go back to the
  /// start (0 seconds).
  loop,

  /// Play to the last keyframe and then stop.
  stopLastKey,

  /// Play to the last key frame and then loop.
  loopLastKey,
}