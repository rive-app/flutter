import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/ellipse.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/paint/solid_color.dart';
import 'package:rive_core/shapes/paint/linear_gradient.dart' as core;
import 'package:rive_core/shapes/paint/radial_gradient.dart' as core;
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/inspector/color/color_type.dart';
import 'package:rive_editor/widgets/inspector/color/inspecting_color.dart';

class TestFileContext extends OpenFileContext {
  TestFileContext(RiveFile file) : super(123, 456) {
    this.core = file;
    makeStage();
  }
}

RiveFile _makeFile() {
  LocalDataPlatform dataPlatform = LocalDataPlatform.make();

  final file = RiveFile(
    'fake',
    localDataPlatform: dataPlatform,
  );

  // Make a somewhat sane file.
  Artboard artboard;
  file.batchAdd(() {
    var backboard = Backboard();
    artboard = Artboard()
      ..name = 'My Artboard'
      ..x = 0
      ..y = 0
      ..width = 1920
      ..height = 1080;

    file.add(backboard);
    file.add(artboard);
  });
  file.captureJournalEntry();
  return file;
}

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

    file.add(shape);
    file.add(fill);
    file.add(solidColor);
    file.add(composer);
    file.add(path);

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
  test('change color of a shape', () {
    var file = _makeFile();
    var shape = _makeShape(file);

    var inspectingColor = InspectingColor.forShapePaints([shape.fills.first]);

    var fileContext = TestFileContext(file);
    inspectingColor.startEditing(fileContext);

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
}
