// -> editor-only
import 'dart:collection';
import 'package:rive_core/math/vec2d.dart';
import 'package:core/id.dart';
import 'package:rive_core/shapes/cubic_vertex.dart';
import 'package:utilities/binary_buffer/binary_writer.dart';

/// Not actually a core path vertex, just used to build up the helper display
/// path used in the editor by things like the pen tool.
class DisplayCubicVertex extends CubicVertex {
  @override
  void changeNonNull() {}

  @override
  Vec2D inPoint;
  @override
  Vec2D outPoint;

  @override
  void onAddedDirty() {}

  @override
  void writeRuntimeProperties(BinaryWriter writer, HashMap<Id, int> idLookup) {}
}
// <- editor-only
