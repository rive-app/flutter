import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_core/shapes/parametric_path.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/rive_clipboard.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

import 'helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('copy uses only top most objects', () async {
    var file = await loadFile('assets/exported/copy_paste_test.riv');
    var core = file.core;
    expect(core.backboard, isNotNull);
    expect(core.backboard.activeArtboard, isNotNull);

    Shape ellipse = core.componentNamed('Ellipse');
    expect(ellipse, isNotNull);

    ParametricPath ellipsePath = core.componentNamed('Ellipse Path');
    expect(ellipsePath, isNotNull);

    Shape rectangle = core.componentNamed('Rectangle');
    expect(rectangle, isNotNull);

    file.selection.selectMultiple([
      ellipse.stageItem,
      ellipsePath.stageItem,
    ]);

    var clipboard = RiveClipboard(file);
    expect(clipboard.paste(file), true);
    core.captureJournalEntry();

    var shapes = core.objectsOfType<Shape>();
    expect(shapes.length, 3,
        reason: 'expect three shapes after pasting the Ellipse');
    expect(core.objectsOfType<ParametricPath>().length, 3,
        reason: 'also expect a second path');
    expect(core.backboard.activeArtboard.drawables.length, 3,
        reason: 'the artboard should now have two drawables');

    // for (final drawable in core.backboard.activeArtboard.drawables) {
    //   print("DRAWABLE: ${drawable.name} ${drawable.drawOrder} ");
    // }
    expect(core.backboard.activeArtboard.drawables[0].drawOrder,
        const FractionalIndex(1, 3));
    expect(core.backboard.activeArtboard.drawables[0], ellipse);

    expect(core.backboard.activeArtboard.drawables[1].drawOrder,
        const FractionalIndex(1, 2));
    expect(core.backboard.activeArtboard.drawables[1], rectangle);

    expect(core.backboard.activeArtboard.drawables[2].drawOrder,
        const FractionalIndex(2, 3));
    // expect(core.backboard.activeArtboard.drawables[2], rectangle);
  });
}
