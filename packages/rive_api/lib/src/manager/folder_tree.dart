import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/plumber.dart';

class FolderTreeManager with Subscriptions {
  FolderTreeManager() {
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
      _folderTrees = _newFolderTrees;
      _plumber.message(_folderTrees);
    }
  }
}
