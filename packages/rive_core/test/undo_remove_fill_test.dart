import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/shape.dart';

import 'src/test_rive_file.dart';

/// Makes sure undoing the deletion of a fill works properly. The trick here is
/// to make sure that deleting an item that contains more items (like fills do,
/// as they contain paint mutators) calls [ContainerComponent.removeRecursive]
/// and not just [Component.remove].
/// 
/// Test for fix to: https://github.com/rive-app/rive/issues/174
void main() {
  test('undoing fill removal works', () {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();

    // Connect client1
    final file = TestRiveFile(
      'fake',
      localDataPlatform: dataPlatform,
      overridePreferences: <String, dynamic>{
        'token': 'fake',
        'clientId': 1,
      },
      useSharedPreferences: false,
    );

    // Create the node with some name set to it.
    var shape = file.add(Shape()..name = 'Colorful');

    const fillColor = Color(0xFFFF0000);
    var fill = shape.createFill(fillColor);
    file.captureJournalEntry();

    expect(shape.fills.length, 1);
    expect(shape.fills.first.paintMutator is SolidColor, true);
    expect((shape.fills.first.paintMutator as SolidColor).color, fillColor);

    fill.removeRecursive();
    file.captureJournalEntry();
    expect(shape.fills.length, 0);

    file.undo();

    expect(shape.fills.length, 1);
    expect(shape.fills.first.paintMutator is SolidColor, true);
    expect((shape.fills.first.paintMutator as SolidColor).color, fillColor);
  });
}
