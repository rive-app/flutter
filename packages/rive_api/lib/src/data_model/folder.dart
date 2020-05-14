/// Tree of directories
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:utilities/deserialize.dart';

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

  static List<FolderDM> fromDataList(List<Object> data) =>
      data.map((d) => FolderDM.fromData(d)).toList(growable: false);

  factory FolderDM.fromData(
    Map<String, Object> data,
  ) =>
      FolderDM(
        id: data.getInt('id'),
        ownerId: data.containsKey('project_owner_id')
            ? data.getInt('project_owner_id')
            : null,
        name: data.getString('name'),
        order: data.getInt('order'),
        parent: data.optInt('parent'),
      );

  @override
  String toString() => 'FolderDM ($id, $name). Parent: $parent';

  @override
  bool operator ==(o) => o is FolderDM && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);
}
