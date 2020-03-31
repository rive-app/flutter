import 'dart:core';

import 'package:rive_api/models/cdn.dart';
import 'package:rive_api/src/deserialize_helper.dart';

/// Rive File metadata from the Api layer. Implementations should inherit from
/// this class in order to add application specific functionality. For example,
/// a UI layer may be interested in selection states or loading image assets.
class RiveApiFile {
  final int id;

  int _ownerId;
  int get ownerId => _ownerId;

  String _name;
  String get name => _name;

  String _preview;
  String get preview => _preview;

  RiveApiFile(this.id, {int ownerId, String name, String preview})
      : _ownerId = ownerId,
        _name = name,
        _preview = preview;

  factory RiveApiFile.fromData(int id, Map<String, dynamic> data) =>
      RiveApiFile(
        id,
        ownerId: data.getInt('oid'),
        name: data.getString('name'),
        preview: data.getString('preview'),
      );

  /// Deserializes file details data, compares it to the file's
  /// current data, and if different, updates the file. Returns
  /// true if the file is updated, false otherwise.
  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    final newFile = RiveApiFile.fromData(id, data);
    newFile._preview = newFile.preview != null
        ? '${cdn.base}${newFile.preview}${cdn.params}'
        : null;
    if (this != newFile) {
      _name = newFile.name;
      _ownerId = newFile.ownerId;
      _preview = newFile.preview;
      return true;
    }
    return false;
  }

  @override
  String toString() => 'RiveFile($id:$_name)';

  @override
  bool operator ==(o) =>
      o is RiveApiFile &&
      id == o.id &&
      ownerId == o.ownerId &&
      name == o.name &&
      preview == o.preview;

  @override
  int get hashCode => id;
}
