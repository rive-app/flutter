import 'package:rive_api/src/manager/subscriptions.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/api/api.dart';
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
  }

  FolderApi _folderApi;
  Plumber _plumber;

  Me _me;
  Iterable<Team> _teams;
  Map<Owner, List<Folder>> _folderMap = Map<Owner, List<Folder>>();
  List<BehaviorSubject<FolderTree>> _folderTrees = [];
  Map<Owner, BehaviorSubject<FolderTree>> _folderTreeMap = {};

  void _handleNewMe(Me me) {
    _me = me;
    _clearFolderList();
    if (me != null) {
      _initFolderTree(me);
      loadFolders(me);
    }
    _publishFolderTrees();
  }

  void _handleNewTeams(Iterable<Team> teams) {
    // lets ditch teams no longer reported.
    _teams = teams;
    Set<Owner> currentOwners = _folderMap.keys.toSet();
    Set<Owner> newOwners = Set<Owner>().union(_teams?.toSet()).union({_me});
    Set<Owner> removeKeys = currentOwners.difference(newOwners);

    removeKeys.forEach((key) {
      _folderMap.remove(key);
      _folderTreeMap[key].close();
      _folderTreeMap.remove(key);
    });

    _teams?.forEach((team) {
      _initFolderTree(team);
      loadFolders(team);
    });

    _publishFolderTrees();
  }

  void _initFolderTree(Owner owner) {
    if (!_folderTreeMap.containsKey(owner)) {
      _folderTreeMap[owner] = BehaviorSubject<FolderTree>();
      _folderTreeMap[owner].add(FolderTree.fromOwner(owner));
    }
  }

  void _clearFolderList() {
    _folderMap.clear();
    _folderTreeMap.values.forEach((bs) => bs.close());
    _folderTreeMap.clear();
  }

  void loadFolders(Owner owner) async {
    final _foldersDM = await _folderApi.folders(owner.asDM);
    final _folders = Folder.fromDMList(_foldersDM.toList());
    _folderMap[owner] = _folders;
    _folderTreeMap[owner].add(FolderTree.fromFolderList(owner, _folders));
    // TODO: still gotta do this which is a real shame
    // gotta sort out our drawer for this really
    _publishFolderTrees();
  }

  void _publishFolderTrees() {
    var _newFolderTrees = _folderTreeMap.values.toList();
    _newFolderTrees.sort((a, b) {
      var _a = a.value;
      var _b = b.value;
      if (_a.owner is Me) return -1;
      if (_b.owner is Me) return 1;
      return _a.owner.displayName.compareTo(_b.owner.displayName);
    });
    _folderTrees = _newFolderTrees;
    _plumber.message(_folderTrees);
  }
}
