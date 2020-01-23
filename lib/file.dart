import 'cdn.dart';
import 'src/deserialize_helper.dart';

class RiveFile {
  final String id;
  String _name;
  String get name => _name;
  String _preview;
  String get preview => _preview;

  RiveFile(this.id);

  void deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    _name = data["name"]?.toString();
    var preview = data.getString('preview');
    if (preview != null) {
      _preview = '${cdn.base}$preview${cdn.params}';
    } else {
      _preview = null;
    }
    print(_preview);
  }

  String toString() => 'RiveFile($id:$_name)';
}
