import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';

void main() {
  Vec2D vector;
  setUpAll(() {
    vector = Vec2D.fromValues(3.14, 456.7);
  });
  test('Init Mat2D from Translation', () {
    // Float precision error requires us to first make a Float32 
    
    final matFromTranslation = Mat2D.fromTranslation(vector);

    expect(matFromTranslation[4], vector[0]);
    expect(matFromTranslation[5], vector[1]);
  });
  
  test('Init Mat2D from Scaling', () {
    final matFromTranslation = Mat2D.fromScaling(vector);

    expect(matFromTranslation[0], vector[0]);
    expect(matFromTranslation[3], vector[1]);
  });
}