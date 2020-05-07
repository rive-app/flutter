import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/plumber.dart';

class FolderTreeManager with Subscriptions {
  static FolderTreeManager _instance = FolderTreeManager._();
  factory FolderTreeManager() => _instance;

  FolderTreeManager._() {
    _plumber = Plumber();
    subscribe<Map<Owner, List<Folder>>>(_handleChange);
  }

  Plumber _plumber;
  List<FolderTree> _folderTrees;

  void _handleChange(Map<Owner, List<Folder>> folderMap) {
    if (folderMap == null) {
      _plumber.clear<List<FolderTree>>();
    } else {
      List<FolderTree> _newFolderTrees = [];
      folderMap.forEach((key, value) {
        _newFolderTrees.add(FolderTree.fromFolderList(key, value));
      });

      _newFolderTrees.sort((a, b) => a.owner.name.compareTo(b.owner.name));
      _folderTrees = _newFolderTrees;
      _plumber.message(_folderTrees);
    }
  }
}
