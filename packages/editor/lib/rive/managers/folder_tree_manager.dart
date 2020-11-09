import 'package:flutter/widgets.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';

class FolderTreeManager with Subscriptions {
  ScrollController scrollController;
  static final FolderTreeManager _instance = FolderTreeManager._();
  factory FolderTreeManager() => _instance;

  FolderTreeManager._() {
    _plumber = Plumber();
    _attach();
  }

  FolderTreeManager.tester() {
    _plumber = Plumber();
    _attach();
  }

  void _attach() {
    subscribe<Me>(_handleNewMe);
    subscribe<List<Team>>(_handleNewTeams);
    subscribe<CurrentDirectory>(_handleNewCurrentDirectory);
  }

  Plumber _plumber;

  Me _me;
  Iterable<Team> _teams;

  List<Owner> get _sortedOwners {
    var owners = <Owner>[
      if (_me != null) _me,
      if (_teams != null) ..._teams,
    ];

    owners.sort((a, b) {
      if (a is Me) return -1;
      if (b is Me) return 1;
      return a.displayName.compareTo(b.displayName);
    });
    return owners;
  }

  void _handleNewMe(Me me) {
    if (_me != null && me != _me) {
      _clearControllers();
    }
    _me = me;
    if (me != null && !me.isEmpty) {
      _initFolderTree(me);
      subscribe<List<Folder>>(_handleNewTeamFolders(me), me.hashCode);
      _publishFolderTreeControllers();
    }
  }

  void _handleNewCurrentDirectory(CurrentDirectory currentDirectory) {
    var controllers = _plumber.peek<List<FolderTreeItemController>>();
    if (controllers != null) {
      controllers.forEach((element) {
        element.select(currentDirectory);
      });
      // TODO: now how do we get the offset of the selected item? any ideas?
      //
      // scrollController.animateTo(100,
      //     duration: const Duration(seconds: 1), curve: Curves.easeIn);
    }
  }

  void _handleNewTeams(Iterable<Team> teams) {
    // lets ditch teams no longer reported.
    _teams = teams;

    Set<Owner> newOwners = <Owner>{}
        .union(_teams != null ? _teams.toSet() : {})
        .union({if (_me != null && !_me.isEmpty) _me});
    Set<Owner> removeKeys = _sortedOwners.toSet().difference(newOwners);

    removeKeys.forEach((key) {
      _plumber.shutdown<FolderTreeItemController>(key.hashCode);
    });

    _teams?.forEach((team) {
      _initFolderTree(team);

      subscribe<List<Folder>>(_handleNewTeamFolders(team), team.hashCode);
    });

    _publishFolderTreeControllers();
  }

  Function(List<Folder>) _handleNewTeamFolders(Owner owner) {
    void _handleNewFolders(List<Folder> folderList) {
      if (folderList == null) {
        _plumber.shutdown<FolderTreeItemController>(owner.hashCode);
        _publishFolderTreeControllers();
      } else {
        _ingestFolders(owner, folderList);
      }
    }

    return _handleNewFolders;
  }

  void _initFolderTree(Owner owner) {
    _plumber.message<FolderTreeItemController>(
      FolderTreeItemController(FolderTree.fromOwner(owner)),
      owner.hashCode,
    );
  }

  void _clearControllers() {
    // put this into the plumber
    _sortedOwners.forEach((owner) {
      _plumber.shutdown<FolderTreeItemController>(owner.hashCode);
    });
    _plumber
        .message<List<FolderTreeItemController>>(<FolderTreeItemController>[]);
  }

  Future<void> _ingestFolders(Owner owner, List<Folder> folders) async {
    final _folderTree = FolderTree.fromFolderList(owner, folders);
    final _curentController =
        _plumber.peek<FolderTreeItemController>(owner.hashCode);

    if (_curentController != null) {
      // lets keep track of whats selected
      var selected = <Folder>{};
      _curentController.items.forEach((element) {
        if (element.selected) {
          selected.add(element.folder);
        }
      });

      // lets keep track of whats opened
      _curentController.data = [_folderTree.root];
      _curentController.items.forEach((element) {
        if (selected.contains(element.folder)) {
          element.selected = true;
        }
      });
      _curentController.refreshExpanded();
      _plumber.message<FolderTreeItemController>(
        _curentController,
        owner.hashCode,
      );
    } else {
      _plumber.message<FolderTreeItemController>(
        FolderTreeItemController(_folderTree),
        owner.hashCode,
      );
    }

    // TODO: until we can use the individual streams we're bound to this
    _publishFolderTreeControllers();
  }

  void _publishFolderTreeControllers() {
    var sortedControllers = _sortedOwners
        .map((owner) => _plumber.peek<FolderTreeItemController>(owner.hashCode))
        .where((controller) => controller != null)
        .toList();
    _plumber.message<List<FolderTreeItemController>>(sortedControllers);
  }
}
