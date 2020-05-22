/// Tree of directories
import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';
import 'package:utilities/utilities.dart';

class FolderDM {
  FolderDM({
    @required this.id,
    @required this.ownerId,
    @required this.name,
    @required this.parent,
    @required this.order,
  });
  final int id;
  final int ownerId;
  final int parent;
  final int order;
  final String name;

  static List<FolderDM> fromDataList(List<dynamic> data, int ownerId) {
    return data
        .map((d) => FolderDM.fromData(d, ownerId))
        .toList(growable: false);
  }

  factory FolderDM.fromData(Map<String, dynamic> data, int ownerId) => FolderDM(
        id: data.getInt('id'),
        ownerId: data.containsKey('project_owner_id')
            ? data.getInt('project_owner_id')
            : ownerId,
        name: data.getString('name'),
        order: data.getInt('order'),
        parent: data.optInt('parent'),
      );

  @override
  String toString() => 'FolderDM ($id, $name). Parent: $parent';

  @override
  bool operator ==(o) => o is FolderDM && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => szudzik(id, ownerId);
}
