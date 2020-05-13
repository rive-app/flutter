import 'package:rive_api/model.dart';

class FolderContents {
  FolderContents(this.files, this.folders);
  FolderContents.empty()
      : files = null,
        folders = null;

  final Iterable<File> files;
  final Iterable<Folder> folders;

  bool get isNotEmpty => files != null && folders != null;
}
