import 'package:flutter/widgets.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_editor/rive/simple_alert.dart';
import 'package:rive_editor/rive/stage/items/stage_path.dart';
import 'package:rive_editor/rive/stage/items/stage_shape.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/rive/stage/tools/pen_tool.dart';

class VectorPenTool extends PenTool<Path> {
  static final VectorPenTool instance = VectorPenTool();

  Path _createdPath;

  @override
  void onEditingChanged(Iterable<Path> paths) {}

  Path _makePath(Vec2D translation) {
    // See if we have an editing shape already.
    // for(final item in editing) {
    //   if(item)
    // }
  }

  @override
  void click(Artboard activeArtboard, Vec2D worldMouse) {
    if (!isShowingGhostPoint) {
      return;
    }

    if (activeArtboard == null) {
      stage.file.addAlert(
        SimpleAlert('Pen tool requires an artboard. Create one first.'),
      );
    }

    if (_createdPath == null) {
      _makePath(ghostPointWorld);
      print("MAKE A PATH");
    }
  }

  @override
  Iterable<Path> getEditingComponents(Iterable<StageItem> solo) {
    // This gets called by the base pen tool to figure out what is currently
    // being edited. The vector pen tool edits paths, so we need to find which
    // paths are in the solo items.
    Set<Path> paths = {};

    // Solo could be null if we've just activated the tool with no selection. We
    // still want this tool to work in this case as the first click will create
    // a shape and path.
    if (solo != null) {
      for (final item in solo) {
        if (item is StageShape) {
          item.component.forEachChild((child) {
            if (child is Path) {
              paths.add(child);
            }
            return true;
          });
        } else if (item is StagePath) {
          paths.add(item.component);
        }
      }
    }
    return paths;
  }
}
