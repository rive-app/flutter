// import 'package:flutter/foundation.dart';
// import 'package:rive_api/src/view_model/view_model.dart';
// import 'package:rxdart/subjects.dart';

// class FolderContentsVM extends ViewModel {
//   const FolderContentsVM(this.folders, this.files);
//   final List<FolderVM> folders;
//   final Iterable<BehaviorSubject<FileDetailsVM>> files;

//   @override
//   String get description => 'FolderContents:\n'
//       '\tFolders: $folders\n'
//       '\tFiles: $files';
// }

// class FolderVM extends ViewModel {
//   const FolderVM(
//     this.id,
//     this.parentId,
//     this.name,
//   );

//   final int id, parentId;
//   final String name;
//   @override
//   String get description =>
//       'Folder: $name, ID: $id, Parent ID: ${parentId ?? 'Root'}';
// }

// class FileDetailsVM extends ViewModel {
//   const FileDetailsVM({
//     @required this.id,
//     @required this.ownerId,
//     this.name,
//   });

//   final int id, ownerId;
//   final String name;

//   @override
//   bool operator ==(Object other) {
//     if (other is FileDetailsVM) {
//       return this.id == other.id &&
//           this.ownerId == other.ownerId &&
//           this.name == other.name;
//     }
//     return false;
//   }

//   @override
//   String get description =>
//       'File ${name ?? 'Loading...'} with id: $id, property of $ownerId';
// }
