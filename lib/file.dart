import 'dart:core';
import 'cdn.dart';
import 'src/deserialize_helper.dart';

/// Rive File metadata from the Api layer. Implementations should inherit from
/// this class in order to add application specific functionality. For example,
/// a UI layer may be interested in selection states or loading image assets.
class RiveApiFile {
  final String id;
  String ownerId;
  String _name;
  String get name => _name;
  String _preview;
  String get preview => _preview;

  RiveApiFile(this.id);

  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    var changed = false;
    ownerId = data["oid"]?.toString();
    var name = data["name"]?.toString();
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
