/// Tree of directories
import 'package:meta/meta.dart';
import 'package:rive_api/src/model/model.dart';

class FolderTree {
  FolderTree({
    @required this.owner,
    @required this.root,
  });
  final Owner owner;
  final FolderTreeItem root;

  factory FolderTree.fromFolderList(Owner owner, List<Folder> folders) {
    final indexMap = Map<int, List<Folder>>();
    // map em out
    folders.forEach((Folder folder) {
      indexMap[folder.parent] ??= [];
      indexMap[folder.parent].add(folder);
    });

    // TODO: bit of a cluster here, parent shoudl be null.
    // but then there's the deleted files confusion here too.
    var _rootFolder = folders.firstWhere((element) => element.id == 1);

    return FolderTree(
        owner: owner, root: FolderTreeItem.create(_rootFolder, indexMap));
  }
}

class FolderTreeItem {
  FolderTreeItem({
    @required this.folder,
    @required this.open,
    @required this.selected,
    @required this.children,
  });
  final Folder folder;
  final bool selected;
  final bool open;
  final List<FolderTreeItem> children;

  factory FolderTreeItem.create(Folder root, Map<int, List<Folder>> indexMap) {
    // Note: Cycles gonna kill us.
    final List<FolderTreeItem> _children = (indexMap.containsKey(root.id))
        ? indexMap[root.id]
            .map((childFolder) => FolderTreeItem.create(childFolder, indexMap))
        : [];
    return FolderTreeItem(
      folder: root,
      children: _children,
      selected: false,
      open: false,
    );
  }
}
