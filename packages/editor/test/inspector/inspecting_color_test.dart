import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inspector/color/color_popout.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inspector/color/inspector_color_swatch.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';

import '../helpers/inspector_helper.dart';
import '../helpers/test_helpers.dart';

Shape _makeShape(RiveFile file) {
  var shape = Shape()..name = 'Ellipse';
  var path = Ellipse()
    ..width = 100
    ..height = 100
    ..name = 'Ellipse Path';

  file.batchAdd(() {
    var composer = PathComposer();
    var solidColor = SolidColor();
    var fill = Fill();

    file.addObject(shape);
    file.addObject(fill);
    file.addObject(solidColor);
    file.addObject(composer);
    file.addObject(path);

    // Let's build up the shape hierarchy:
    // Artboard
    // │
    // └─▶ Shape
    //       │
    //       ├─▶ Fill
    //       │     │
    //       │     └─▶ SolidColor
    //       │
    //       ├─▶ PathComposer
    //       │
    //       └─▶ Path
    shape.appendChild(path);
    shape.appendChild(composer);
    shape.appendChild(fill);
    fill.appendChild(solidColor);
    file.artboards.first.appendChild(shape);
  });
  return shape;
}

void main() {
  OpenFileContext file;
  Shape shape;

  setUp(() async {
    file = await makeFile();
    shape = _makeShape(file.core);
  });

  tearDown(() => file.dispose());

  test('change color of a shape', () async {
    var inspectingColor = InspectingColor.forShapePaints([shape.fills.first]);

    inspectingColor.startEditing(file);

    expect(inspectingColor.type.value, ColorType.solid);

    // Change color to magenta and expect the change to propagate to the fill.
    const magenta = Color(0xFFF9537E);
    inspectingColor.changeColor(HSVColor.fromColor(magenta));
    expect(shape.fills.first.paintMutator is SolidColor, true);
    var solidColor = shape.fills.first.paintMutator as SolidColor;
    expect(solidColor.color, magenta);

    inspectingColor.changeType(ColorType.linear);
    expect(shape.fills.first.paintMutator is core.LinearGradient, true);

    inspectingColor.changeType(ColorType.radial);
    expect(shape.fills.first.paintMutator is core.RadialGradient, true);
  });

  testWidgets('enter and exit color picker works', (tester) async {
    file.select(shape.stageItem);

    await tester.pumpWidget(TestInspector(file: file));
    await tester.pumpAndSettle();

    // Expect that the inspector ui is displaying options for a shape
    await expectLater(
      find.byType(InspectorPanel),
      matchesGoldenFile('../assets/goldens/inspecting_color_shape_test.png'),
    );

    var colorSwatch = find.byType(InspectorColorSwatch);
    await tester.tap(colorSwatch.first);
    await tester.pumpAndSettle();

    var colorPopout = find.byType(ColorPopout);

    expect(colorPopout, findsOneWidget);

    const mousePos = Offset(2000, 2000);

    file.stage.mouseMove(0, mousePos.dx, mousePos.dy);
    file.stage.mouseDown(0, mousePos.dx, mousePos.dy);
    file.stage.mouseUp(0, mousePos.dx, mousePos.dy);

    expect(file.selection.isEmpty, true,
        reason: 'clicking on an empty spot on the stage '
            'should\'ve cleared the selection');
    file.advance(0);
    await tester.pumpAndSettle();

    // Expect that the inspector ui is back to it's default state
    await expectLater(
      find.byType(InspectorPanel),
      matchesGoldenFile('../assets/goldens/inspecting_color_default_test.png'),
    );
  });
}
