import 'dart:collection';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:core/id.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:utilities/binary_buffer/binary_reader.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';
import 'package:utilities/utilities.dart';

class RiveClipboard {
  Uint8List bytes;
  Set<Component> copiedComponents;

  RiveClipboard(OpenFileContext file)
      : assert(file != null, 'can\'t copy from null file') {
    // TODO: figure out if we're copying keyframes or components for the
    // hierarchy.

    // Assume copying components from hierarchy. Build up the list of actual
    // items to copy.
    var components =
        <Component>{}; //file.selection.items.whereType<Component>().toSet();
    for (final item in file.selection.items) {
      if (item is StageItem && item.component is Component) {
        components.add(item.component as Component);
      }
    }
    copiedComponents = <Component>{};

    for (final component in tops(components)) {
      // This is a top level component, add it and any of its children to the
      // copy set.
      copiedComponents.add(component);
      if (component is ContainerComponent) {
        component.forEachChild((child) {
          copiedComponents.add(child);
          return true;
        });
      }
    }

    HashMap<Id, int> idToIndex = HashMap<Id, int>();
    int index = 0;
    for (final component in copiedComponents) {
      idToIndex[component.id] = index++;
    }

    var writer = BinaryWriter();
    writer.writeVarUint(copiedComponents.length);
    for (final component in copiedComponents) {
      component.writeRuntime(writer, idToIndex);
    }
    bytes = writer.uint8Buffer;
  }

  bool paste(OpenFileContext file) {
    // TODO: what are we pasting into?
    // If no component is selected, it's the activeArtboard.
    //    EDGECASE: no artboard? compute max aabb of contents and make one that fits
    //    FORNOW: skip paste...
    // If selected component is in the copiedComponents set, paste to the artboard at the same location.
    // Otherwise center to selected component
    var selectedItems = file.selection.items;
    var selectedItem = selectedItems.isNotEmpty ? selectedItems.last : null;
    Component pasteDestination;
    if (selectedItem is StageItem &&
        selectedItem.component is Component &&
        !copiedComponents.contains(selectedItem.component)) {
      pasteDestination = selectedItem.component as Component;
    } else {
      pasteDestination = file.core.backboard.activeArtboard;
    }

    // print("DESTINATION: $pasteDestination");

    var reader = BinaryReader.fromList(bytes);
    var numObjects = reader.readVarUint();
    var core = file.core;

    var idRemap = RuntimeIdRemap(core.idType, core.intType);
    var drawOrderRemap = DrawOrderRemap(core.fractionalIndexType, core.intType);
    var remaps = <RuntimeRemap>[idRemap, drawOrderRemap];

    var targetArtboard = pasteDestination.artboard;
    var objects = List<Component>(numObjects);
    core.batchAdd(() {
      for (int i = 0; i < numObjects; i++) {
        var component = core.readRuntimeObject<Component>(reader, remaps);
        if (component != null) {
          // TODO: kill
          if (component.name != null) {
            component.name = 'PASTED: ${component.name}';
          }
          objects[i] = component;
          core.addObject(component);
        }
      }

      // Patch up the draw order using the last drawable as the min for the
      // newly added drawables.
      drawOrderRemap.remap(
          core,
          targetArtboard.drawables.isNotEmpty
              ? targetArtboard.drawables.last?.drawOrder
              : null);

      // Perform the id remapping.
      for (final remap in idRemap.properties) {
        var id = objects[remap.value]?.id;
        if (id != null) {
          core.setObjectProperty(remap.object, remap.propertyKey, id);
        }
      }

      // Any component objects with no id map to the pasteDestination.
      for (final object in objects) {
        if (object is Component && object.parentId == null) {
          object.parentId = pasteDestination.id;
        }
      }
    });

    // Finally select the newly added items...
    var selection = <StageItem>{};
    for (final component in objects) {
      if (component == null || component.stageItem == null) {
        continue;
      }
      selection.add(component.stageItem);
    }
    if (selection.isNotEmpty) {
      file.selection.selectMultiple(selection);
    }

    // targetArtboard.advance(0);
    return true;
  }
}
