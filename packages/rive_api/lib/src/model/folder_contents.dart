import 'package:rive_api/model.dart';

class FolderContents {
  const FolderContents({this.files, this.folders, this.isLoading = false});

  final List<File> files;
  final List<Folder> folders;

  /// Flag to signal if contents are still being loaded.
  final bool isLoading;
}
