import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/shapes/triangle.dart';
import 'package:rive_core/shapes/rectangle.dart';

void main() {
  group('Triangle', () {
    test('Test triangle has three points', () {
      var triangle = Triangle()
        ..width = 10
        ..height = 5;
      expect(triangle.vertices.length, 3);
    });

    test('Test triangles vertices are bottom left, bottom right, top middle',
        () {
      var triangle = Triangle()
        ..width = 10
        ..height = 5;
      expect(triangle.vertices[0].x, 0);
      expect(triangle.vertices[0].y, -2.5);

      expect(triangle.vertices[1].x, 5);
      expect(triangle.vertices[1].y, 2.5);

      expect(triangle.vertices[2].x, -5);
      expect(triangle.vertices[2].y, 2.5);
    });
  });

  group('Rectangle', () {
    test('Test rectangle has four points', () {
      var shape = Rectangle()
        ..width = 10
        ..height = 5;
      expect(shape.vertices.length, 4);
    });

    test('Test rectangle vertices start top left and move around', () {
      var shape = Rectangle()
        ..width = 10
        ..height = 5;
      expect(shape.vertices[0].x, -5);
      expect(shape.vertices[0].y, -2.5);

      expect(shape.vertices[1].x, 5);
      expect(shape.vertices[1].y, -2.5);

      expect(shape.vertices[2].x, 5);
      expect(shape.vertices[2].y, 2.5);

      expect(shape.vertices[3].x, -5);
      expect(shape.vertices[3].y, 2.5);
    });
  });
}
