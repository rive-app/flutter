/// Tree of directories
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:rive_api/src/data_model/data_model.dart';

class Folder {
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
  final String name;

  static List<Folder> fromDMList(List<FolderDM> folders) {
    return folders.map((folder) => Folder.fromDM(folder)).toList();
  }

  factory Folder.fromDM(FolderDM folder) {
    // NOTE:
    // Lets just pretend 'deleted files' lives inside your files
    // Your Files is id 1
    // Deleted Files is id 0
    var _parent = folder.parent;
    if (_parent == null && folder.id == 0) {
      _parent = 1;
    }
    return Folder(
      ownerId: folder.ownerId,
      name: folder.name,
      parent: _parent,
      order: folder.order,
      id: folder.id,
    );
  }

  @override
  bool operator ==(o) => o is Folder && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);

  FolderDM get asDM => FolderDM(
        ownerId: ownerId,
        name: name,
        parent: parent,
        order: order,
        id: id,
      );

  @override
  String toString() => 'Folder: $id, $name, $ownerId';
}
