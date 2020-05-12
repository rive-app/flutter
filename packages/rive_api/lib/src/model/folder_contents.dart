import 'package:rive_api/model.dart';

class FolderContents {
  FolderContents(this.files, this.folders);

  final Iterable<File> files;
  final Iterable<Folder> folders;
}
