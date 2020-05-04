import 'package:rive_api/src/view_model/view_model.dart';

class FolderContents extends ViewModel {
  const FolderContents(this.folders, this.files);
  final List<Folder> folders;
  final List<File> files;

  @override
  String get description => 
  'FolderContents:\n'
  '\tFolders: $folders\n'
  '\tFiles: $files';
}

class Folder extends ViewModel {
  const Folder(
    this.id,
    this.parentId,
    this.name,
  );

  final int id, parentId;
  final String name;
  @override
  String get description =>
      'Folder: $name, ID: $id, Parent ID: ${parentId ?? 'Root'}';
}

class File extends ViewModel {
  const File(this.id, this.name);

  final int id;
  final String name;
  // More info??

  @override
  String get description => 'File: $name, ID: $id';
}