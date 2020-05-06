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
    var _defaultParent =
        folders.firstWhere((element) => element.name == 'Your Files').id;
    return folders
        .map((folder) => Folder.fromDM(folder, _defaultParent))
        .toList();
  }

  factory Folder.fromDM(FolderDM folder, int defaultParent) {
    var _parent = folder.parent;
    if (_parent == null && folder.id != defaultParent) {
      _parent = defaultParent;
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
}

class ActiveFolder extends Folder {}

class SelectedFolder extends Folder {}
