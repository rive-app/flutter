/// Tree of directories
import 'package:rive_api/model.dart';

class Selection {
  Selection({
    Set<File> files,
    Set<Folder> folders,
  })  : this.files = files ?? <File>{},
        this.folders = folders ?? <Folder>{};

  final Set<File> files;
  final Set<Folder> folders;

  bool get isEmpty => files.isEmpty && folders.isEmpty;
}
