/// Tree of directories
import 'package:meta/meta.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/model.dart';
import 'package:rxdart/subjects.dart';

class FolderTree {
  FolderTree({
    @required this.owner,
    @required this.root,
  });
  final Owner owner;
  final FolderTreeItem root;

  factory FolderTree.fromOwner(Owner owner) {
    return FolderTree(owner: owner, root: FolderTreeItem.dummy(owner));
  }

  factory FolderTree.fromFolderList(Owner owner, List<Folder> folders) {
    final indexMap = <int, List<Folder>>{};

    // map em out
    folders.forEach((Folder folder) {
      if (folder.parent != null) {
        indexMap[folder.parent] ??= [];
        indexMap[folder.parent].add(folder);
      }
    });

    var _rootFolder =
        folders.firstWhere((element) => element.name == 'Your Files');
    return FolderTree(
        owner: owner,
        root: FolderTreeItem.create(_rootFolder, indexMap, owner));
  }
}

class FolderTreeItem {
  FolderTreeItem({@required this.folder, @required this.children, this.owner}) {
    hover = false;

    final currentDirectory = Plumber().peek<CurrentDirectory>();
    if (currentDirectory != null &&
        (currentDirectory.folderId == folder?.id &&
            currentDirectory.owner == owner)) {
      selected = true;
    } else {
      selected = false;
    }
  }
  final Folder folder;
  final _hover = BehaviorSubject<bool>();
  final _selected = BehaviorSubject<bool>();
  final Owner owner;
  final List<FolderTreeItem> children;

  String get iconURL {
    return owner?.avatarUrl;
  }

  String get name {
    return (owner == null) ? folder.name : owner.displayName;
  }

  BehaviorSubject<bool> get hoverStream => _hover;
  BehaviorSubject<bool> get selectedStream => _selected;
  bool get selected => _selected.value == true;
  bool get hover => _hover.value == true;

  set selected(bool value) {
    if (selected != value) {
      _selected.add(value);
    }
  }

  set hover(bool value) {
    if (hover != value) {
      _hover.add(value);
    }
  }

  factory FolderTreeItem.dummy(Owner owner) {
    return FolderTreeItem(
      folder: null,
      children: [],
      owner: owner,
    );
  }

  factory FolderTreeItem.create(Folder root, Map<int, List<Folder>> indexMap,
      [Owner owner]) {
    // Note: Cycles gonna kill us.
    final List<FolderTreeItem> _children = (indexMap.containsKey(root.id))
        ? indexMap[root.id]
            .map((childFolder) => FolderTreeItem.create(childFolder, indexMap))
            .toList()
        : [];
    return FolderTreeItem(
      folder: root,
      children: _children,
      owner: owner,
    );
  }
}
