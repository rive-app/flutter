@Timeout(Duration(seconds: 1))

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rive_api/model.dart';

import 'package:rive_api/src/plumber.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/managers/folder_tree_manager.dart';

import 'helpers/test_helpers.dart';
import 'helpers/test_models.dart';

void main() {
  group('Notification Manager ', () {
    FolderTreeManager folderTreeManager;
    setUp(() {
      // what IS the cycle for these guys, we're just listening to stuff
      // do they stick around forever?
      folderTreeManager = FolderTreeManager.tester();
    });
    tearDown(() {
      Plumber().reset();
    });

    test('Simple me notification', () async {
      final me = getMe();
      final someoneElse = getMe(ownerId: 999);
      final nobody = getMe(ownerId: null);

      final testComplete = testStream(
        Plumber().getStream<List<FolderTreeItemController>>(),
        [
          // get a list with me controller.
          (List<FolderTreeItemController> constrollers) =>
              constrollers.length == 1,
          // someoneElse!!, clear the list
          (List<FolderTreeItemController> constrollers) => constrollers.isEmpty,
          // someoneElse loads
          (List<FolderTreeItemController> constrollers) =>
              constrollers.length == 1,
          // nobody, clear the list
          (List<FolderTreeItemController> constrollers) => constrollers.isEmpty,
        ],
      );

      final testMeComplete = testStream(
        Plumber().getStream<FolderTreeItemController>(me.hashCode),
        [
          // get a list with me controller.
          (FolderTreeItemController controller) => controller.owner == me
        ],
      );
      final testSomeoneElseComplete = testStream(
        Plumber().getStream<FolderTreeItemController>(someoneElse.hashCode),
        [
          // get a list with me controller.
          (FolderTreeItemController controller) =>
              controller.owner == someoneElse
        ],
      );

      // these events will compress down unpredictably if
      // if we just fire them all in at once.
      Plumber().message(me);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(someoneElse);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(nobody);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      await testComplete.future;
      await testMeComplete.future;
      await testSomeoneElseComplete.future;
    });

    test('Simple team notification', () async {
      final teams = getTeams(3);

      final testComplete = testStream(
        Plumber().getStream<List<FolderTreeItemController>>(),
        [
          // get a 3 team controllers
          (List<FolderTreeItemController> constrollers) =>
              constrollers.length == 3,
          // list reduced to 2
          (List<FolderTreeItemController> constrollers) =>
              constrollers.length == 1,
          // list emptied
          (List<FolderTreeItemController> constrollers) => constrollers.isEmpty,
        ],
      );

      // these events will compress down unpredictably if
      // if we just fire them all in at once.
      Plumber().message(teams);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(teams.sublist(2));
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));
      Plumber().message(<Team>[]);
      await Future<dynamic>.delayed(const Duration(milliseconds: 10));

      await testComplete.future;
    });
  });
}
