import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/bones/weighted_vertex.dart';

class TestWeightedVertex extends WeightedVertex {
  @override
  int weightIndices = 0;

  @override
  int weights = 0;
}

void main() {
  test('changing weights set the right values', () {
    // Vertices can have at most 4 weights.
    var vertex = TestWeightedVertex();

    // If we set a single weight to 100% it should have that single weight at
    // 100%.
    vertex.setWeight(0, 5, 1);
    expect(vertex.getWeight(0), 1);

    // If we set the second weight to 50%, the first weight should go down to
    // %50.
    vertex.setWeight(1, 5, 0.5);
    expect(vertex.getWeight(0), const IsApproximately(0.5));
    expect(vertex.getWeight(1), const IsApproximately(0.5));

    // If we set first tendon's weight to 0, the second one should go up to
    // %100.
    vertex.setWeight(0, 5, 0.0);
    expect(vertex.getWeight(0), 0);
    expect(vertex.getWeight(1), 1);

    vertex.setWeight(0, 5, 1.0);
    vertex.setWeight(1, 5, 0.8);
    vertex.setWeight(2, 5, 0.9);
    vertex.setWeight(3, 5, 0.2);
    vertex.setWeight(4, 5, 0.7);

    double sum = 0;
    for (int i = 0; i < 5; i++) {
      sum += vertex.getWeight(i);
    }
    expect(sum, 1);
  });
}

class IsApproximately extends Matcher {
  final double value;
  const IsApproximately(this.value);
  @override
  bool matches(dynamic item, Map matchState) =>
      item is double && (item - value).abs() < 0.01;

  @override
  Description describe(Description description) =>
      description.add('approximately $value');
}
