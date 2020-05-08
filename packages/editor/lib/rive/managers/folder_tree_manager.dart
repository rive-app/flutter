import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/api.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rxdart/rxdart.dart';

class FolderTreeManager with Subscriptions {
  static FolderTreeManager _instance = FolderTreeManager._();
  factory FolderTreeManager() => _instance;

  FolderTreeManager._() {
    _folderApi = FolderApi();
    _plumber = Plumber();

    // TODO: can be moved once our FileManager is more capable.
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
    subscribe<CurrentDirectory>(_handleNewCurrentDirectory);
  }

  FolderApi _folderApi;
  Plumber _plumber;

  Me _me;
  Iterable<Team> _teams;
  Map<Owner, List<Folder>> _folderMap = Map<Owner, List<Folder>>();
  List<BehaviorSubject<FolderTreeItemController>> _folderTreeControllers = [];
  Map<Owner, BehaviorSubject<FolderTreeItemController>>
      _folderTreeControllerMap = {};

  void _handleNewMe(Me me) {
    _me = me;
    _clearFolderList();
    if (me != null) {
      _initFolderTree(me);
      loadFolders(me);
    }
    _publishFolderTreeControllers();
  }

  void _handleNewCurrentDirectory(CurrentDirectory currentDirectory) {
    _folderTreeControllers.forEach((element) {
      element.value.select(currentDirectory);
    });
  }

  void _handleNewTeams(Iterable<Team> teams) {
    // lets ditch teams no longer reported.
    _teams = teams;
    Set<Owner> currentOwners = _folderMap.keys.toSet();
    Set<Owner> newOwners = <Owner>{}.union(_teams?.toSet()).union({_me});
    Set<Owner> removeKeys = currentOwners.difference(newOwners);

    removeKeys.forEach((key) {
      _folderMap.remove(key);
      _folderTreeControllerMap[key].close();
      _folderTreeControllerMap.remove(key);
    });

    _teams?.forEach((team) {
      _initFolderTree(team);
      loadFolders(team);
    });

    _publishFolderTreeControllers();
  }

  void _initFolderTree(Owner owner) {
    if (!_folderTreeControllerMap.containsKey(owner)) {
      _folderTreeControllerMap[owner] =
          BehaviorSubject<FolderTreeItemController>();
      _folderTreeControllerMap[owner]
          .add(FolderTreeItemController(FolderTree.fromOwner(owner)));
    }
  }

  void _clearFolderList() {
    _folderMap.clear();
    _folderTreeControllerMap.values.forEach((bs) => bs.close());
    _folderTreeControllerMap.clear();
  }

  Future<void> loadFolders(Owner owner) async {
    final _foldersDM = await _folderApi.folders(owner.asDM);
    final _folders = Folder.fromDMList(_foldersDM.toList());
    _folderMap[owner] = _folders;
    _folderTreeControllerMap[owner].add(
        FolderTreeItemController(FolderTree.fromFolderList(owner, _folders)));
    // TODO: still gotta do this which is a real shame
    // gotta sort out our drawer for this really
    _publishFolderTreeControllers();
  }

  void _publishFolderTreeControllers() {
    var _newFolderTreeControllers = _folderTreeControllerMap.values.toList();
    _newFolderTreeControllers.sort((a, b) {
      var _a = a.value;
      var _b = b.value;
      if (_a.data.first.owner is Me) return -1;
      if (_b.data.first.owner is Me) return 1;
      return _a.data.first.owner.displayName
          .compareTo(_b.data.first.owner.displayName);
    });
    _folderTreeControllers = _newFolderTreeControllers;
    _plumber.message(_folderTreeControllers);
  }
}
