import 'dart:ui';

// ignore: one_member_abstracts
abstract class StrokeEffect {
  Path effectPath(Path source);
  void invalidateEffect();
}
