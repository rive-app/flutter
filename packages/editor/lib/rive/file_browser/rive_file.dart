import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/cdn.dart';
import 'package:rive_api/models/file.dart';
import 'package:rive_core/selectable_item.dart';

import 'file_browser.dart';

/// Metadata for a file stored on the Rive cloud.
class RiveFile extends RiveApiFile with SelectableItem, ChangeNotifier {
  final ValueKey<int> key;
  final FileBrowser browser;
  bool _loaded = false;

  final _draggingState = ValueNotifier<bool>(false);

  RiveFile(int id, this.browser)
      : key = ValueKey<int>(id),
        super(id);

  ValueListenable<bool> get draggingState => _draggingState;
  bool get isDragging => _draggingState.value;
  set isDragging(bool val) => _draggingState.value = val;

  /// Clear out the loaded flag so that the next [needDetails] call can queue a
  /// re-load of the details.
  void allowReloadDetails() {
    _loaded = false;
  }

  /// This is called by the RiveApi when it has new data for the file, we take
  /// the opportunity to notify the UI that generally the metadata has changed.
  /// We could also store each property as an individual change notifier, but
  /// because there can be lots of small fields, this is the current approach.
  @override
  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    _loaded = true;
    if (super.deserialize(cdn, data)) {
      // notify if deserialize changes some value...
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Lets the browser know that the UI layer no longer needs the file details.
  /// This allows the browser to remove it from the next load batch list. It's
  /// important to call this when files go out of scope from long lists as the
  /// user could be quickly scrolling through and we don't want to fill up the
  /// queue/batch with files that won't be immediately helpful to see the
  /// details of.
  void doneWithDetails() {
    browser.dequeueLoadDetails(this);
  }

  /// Lets the browser know that the details are necessary and should be
  /// refreshed/loaded as soon as possible. This is passed on to the browser so
  /// that it can debounce and batch load multiple file details.
  void needDetails() {
    if (!_loaded) {
      browser.queueLoadDetails(this);
    }
  }
}
