import 'cdn.dart';
import 'src/deserialize_helper.dart';

class RiveApiFile {
  final String id;
  String _name;
  String get name => _name;
  String _preview;
  String get preview => _preview;

  RiveApiFile(this.id);

  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    var changed = false;
    var name = data["name"]?.toString();
    if(_name != name) {
      _name = name;
      changed = true;
    }
    var preview = data.getString('preview');
    var url = preview != null ? '${cdn.base}$preview${cdn.params}' : null;
    if(_preview != url){
      _preview = url;
      changed = true;
    }
    return changed;
  }

  String toString() => 'RiveFile($id:$_name)';
}
