import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';

void main() {
  test('aabb can be computed from points', () {
    List<Vec2D> points = [
      Vec2D.fromValues(2, 3),
      Vec2D.fromValues(0, 0),
      Vec2D.fromValues(-10, -5),
      Vec2D.fromValues(1, 0),
    ];
    var bounds = AABB.fromPoints(points);
    expect(bounds.minimum[0], -10);
    expect(bounds.minimum[1], -5);
    expect(bounds.maximum[0], 2);
    expect(bounds.maximum[1], 3);
  });

  test('aabb can be computed from transformed points', () {
    var xform = Mat2D.fromTranslation(Vec2D.fromValues(1, 0));
    List<Vec2D> points = [
      Vec2D.fromValues(2, 3),
      Vec2D.fromValues(0, 0),
      Vec2D.fromValues(-10, -5),
      Vec2D.fromValues(1, 0),
    ];
    var bounds = AABB.fromPoints(points, transform: xform);
    expect(bounds.minimum[0], -9);
    expect(bounds.minimum[1], -5);
    expect(bounds.maximum[0], 3);
    expect(bounds.maximum[1], 3);
  });

  test('0 height aabb expands', () {
    List<Vec2D> points = [
      Vec2D.fromValues(2, 0),
      Vec2D.fromValues(-10, 0),
    ];
    var bounds = AABB.fromPoints(points, expand: 10);
    expect(bounds.minimum[0], -10);
    expect(bounds.minimum[1], -5);
    expect(bounds.maximum[0], 2);
    expect(bounds.maximum[1], 5);
  });
}
