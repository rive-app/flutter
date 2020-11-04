/// Tree of directories
import 'package:meta/meta.dart';
import 'package:rive_api/data_model.dart';
import 'named.dart';

class Folder implements Named {
  Folder({
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
  @override
  final String name;

  static List<Folder> fromDMList(List<FolderDM> folders) {
    return folders.map((folder) => Folder.fromDM(folder)).toList();
  }

  factory Folder.fromDM(FolderDM folder) {
    var _parent = folder.parent;
    return Folder(
      ownerId: folder.ownerId,
      name: folder.name,
      parent: _parent,
      order: folder.order,
      id: folder.id,
    );
  }

  @override
  bool operator ==(Object o) =>
      o is Folder && o.id == id;

  @override
  int get hashCode => id;

  FolderDM get asDM => FolderDM(
        ownerId: ownerId,
        name: name,
        parent: parent,
        order: order,
        id: id,
      );

  @override
  String toString() =>
      '< Folder: id: $id, n: $name, oid: $ownerId, pid: $parent >';
}
