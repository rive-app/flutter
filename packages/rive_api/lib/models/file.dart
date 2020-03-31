import 'dart:core';

import 'package:rive_api/models/cdn.dart';
import 'package:rive_api/src/deserialize_helper.dart';

/// Rive File metadata from the Api layer. Implementations should inherit from
/// this class in order to add application specific functionality. For example,
/// a UI layer may be interested in selection states or loading image assets.
class RiveApiFile {
  final int id;

  int ownerId;

  String _name;
  String get name => _name;

  String _preview;
  String get preview => _preview;

  RiveApiFile(this.id, {this.ownerId, String name, String preview})
      : _name = name,
        _preview = preview;

  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    var changed = false;
    ownerId = data.getInt('oid');
    var name = data['name']?.toString();
    if (_name != name) {
      _name = name;
      changed = true;
    }
    var preview = data.getString('preview');
    var url = preview != null ? '${cdn.base}$preview${cdn.params}' : null;
    if (_preview != url) {
      _preview = url;
      changed = true;
    }
    return changed;
  }

  @override
  String toString() => 'RiveFile($id:$_name)';
}
