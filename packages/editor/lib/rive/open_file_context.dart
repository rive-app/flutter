import 'package:flutter/foundation.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/files.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/stage/stage.dart';

/// Helper for state managed by a single open file. The file may be open (in a
/// tab) but it is not guaranteed to be in memory.
class OpenFileContext {
  /// Globally unique identifier set for the file, composed of ownerId/fileId.
  final int ownerId;
  final int fileId;

  /// The base Rive API.
  final RiveApi api;

  /// The files api.
  // final RiveFilesApi filesApi;

  /// File name
  final ValueNotifier<String> name;

  /// The Core representation of the file.
  RiveFile coreContext;

  /// The Stage data for this file.
  Stage stage;

  OpenFileContext(
    this.ownerId,
    this.fileId, {
    String fileName,
    this.api,
    // this.filesApi,
  }) : name = ValueNotifier<String>(fileName);

  Future<bool> connect() async {
    // coreContext = RiveFile('$ownerId/$fileId/$token', api: api);
    return true;
  }
}
