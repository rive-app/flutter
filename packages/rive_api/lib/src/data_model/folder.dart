/// Tree of directories
import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';
import 'package:utilities/utilities.dart';

class FolderDM {
  static const int allId = -1;
  static const int trashId = -2;

  FolderDM({
    @required this.id,
    @required this.ownerId,
    @required this.name,
    @required this.order,
    this.parent,
  })  : assert(id != null),
        assert(ownerId != null),
        assert(order != null),
        assert(name != null);
  final int id;

  // TODO: Can we nuke this now?
  final int ownerId;

  final int parent;
  final int order;
  final String name;

  FolderDM.root(this.ownerId)
      : id = allId,
        order = -1,
        name = null,
        parent = null;

  static List<FolderDM> fromDataList(
      List<Map<String, dynamic>> data, int ownerId) {
    return data.map((d) => FolderDM.fromData(d, ownerId)).toList()
      ..add(FolderDM.root(ownerId))
      ..add(FolderDM(
        id: trashId,
        ownerId: ownerId,
        name: 'Trash',
        order: FolderDM.trashId,
        parent: allId,
      ));
  }

  factory FolderDM.fromData(Map<String, dynamic> data, int ownerId) => FolderDM(
        id: data.getInt('id'),
        ownerId: ownerId,
        name: data.getString('name'),
        order: data.getInt('order'),
        parent: data.optInt('parent_id') ?? allId,
      );

  @override
  String toString() => 'FolderDM ($id, $name). Parent: $parent';

  @override
  bool operator ==(Object o) => o is FolderDM && o.id == id;

  @override
  int get hashCode => id;
}
