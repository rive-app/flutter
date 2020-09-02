import 'dart:core';

import 'package:rive_api/models/cdn.dart';
import 'package:utilities/deserialize.dart';

/// Rive File metadata from the Api layer. Implementations should inherit from
/// this class in order to add application specific functionality. For example,
/// a UI layer may be interested in selection states or loading image assets.
class RiveApiFile {
  final int id;

  int _ownerId;
  int get ownerId => _ownerId;

  String _name;
  String get name => _name;

  String _thumbnail;
  String get thumbnail => _thumbnail;

  RiveApiFile(this.id, {int ownerId, String name, String thumbnail})
      : _ownerId = ownerId,
        _name = name,
        _thumbnail = thumbnail;

  factory RiveApiFile.fromData(int id, Map<String, dynamic> data) =>
      RiveApiFile(
        id,
        ownerId: data.getInt('oid'),
        name: data.getString('name'),
        thumbnail: data.getString('thumbnail'),
      );

  /// Deserializes file details data, compares it to the file's
  /// current data, and if different, updates the file. Returns
  /// true if the file is updated, false otherwise.
  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    final newFile = RiveApiFile.fromData(id, data);
    newFile._thumbnail = newFile.thumbnail != null
        ? '${cdn.base}${newFile.thumbnail}${cdn.params}'
        : null;
    if (this != newFile) {
      _name = newFile.name;
      _ownerId = newFile.ownerId;
      _thumbnail = newFile.thumbnail;
      return true;
    }
    return false;
  }

  @override
  String toString() => 'RiveFile($id:$_name)';

  @override
  bool operator ==(Object o) =>
      o is RiveApiFile &&
      id == o.id &&
      ownerId == o.ownerId &&
      name == o.name &&
      thumbnail == o.thumbnail;

  @override
  int get hashCode => id;
}
