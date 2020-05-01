import 'dart:async';
import 'package:rxdart/rxdart.dart';

import 'package:rive_api/src/view_model/view_model.dart';

class SelectionManager {
  SelectionManager({StreamController<DirectoryVM> activeDirController})
      : _activeDirOutput =
            activeDirController ?? BehaviorSubject<DirectoryVM>();

  /*
   * Outbound
   */

  /// The active directory can be set from the directory's sub-directories
  final BehaviorSubject<DirectoryVM> _activeDirOutput;
  Stream<DirectoryVM> get activeDirStream => _activeDirOutput.stream;

  /*
   * Inbound
   */

  /// Change the active directory
  void changeActiveDir(DirectoryVM dir) => _activeDirOutput.add(dir);
}
