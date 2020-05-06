// import 'dart:async';
// import 'dart:math';

// import 'package:rive_api/src/old/manager/subscriptions.dart';
// import 'package:rive_api/src/plumber.dart';
// import 'package:rive_api/src/old/view_model/view_model.dart';
// import 'package:rxdart/subjects.dart';

// class FolderContentsManager with Subscriptions {
//   FolderContentsManager() {
//     print("Let's listen to the current directory!");
//     subscribe<CurrentDirectoryVM>((directory) {
//       // This is set up to listen to directory change events, and return new info.
//       print("A new folder has been pushed here! $directory");
//       _getFolder(directory.id);
//     });
//   }

//   static final Map<int, BehaviorSubject<FileDetailsVM>> _idToFilePipe = {};

//   static void _getFolder(int id) async {
//     List<FolderVM> folders;
//     List<FileDetailsVM> files;
//     if (id == 0) {
//       // get top folder:
//       folders = [
//         // All 'null' parentIds, all contained in the top folder.
//         FolderVM(0, null, 'Deleted Files'),
//         FolderVM(1, null, 'Your Files'),
//         FolderVM(2, null, 'Test Folder'),
//       ];

//       files = [
//         FileDetailsVM(id: 0, ownerId: 16),
//         FileDetailsVM(id: 1, ownerId: 16),
//       ];
//     } else {
//       folders = [
//         // Inner folder. Its parentId is '2', this is a child of 'Test Folder' above.
//         FolderVM(3, 2, 'Inner Folder'),
//       ];
//       files = [
//         FileDetailsVM(id: 4, ownerId: 16),
//         FileDetailsVM(id: 5, ownerId: 16),
//       ];
//     }

//     // First propagate the initial details (no name).
//     _updateFileDetails(files);

//     final fileIds = files.map((e) => e.id);
//     // Tell the system to go load the details from the network.
//     _loadDetails(fileIds);
//     final filePipes = files.map((f) => _idToFilePipe[f.id]);

//     Plumber().message(FolderContentsVM(folders, filePipes));
//   }

//   /// Propagates the given list of [FileDetails] through their Streams.
//   /// Will only propagate if needed.
//   static void _updateFileDetails(Iterable<FileDetailsVM> files) async {
//     for (final file in files) {
//       _idToFilePipe[file.id] ??= BehaviorSubject<FileDetailsVM>();

//       final pipe = _idToFilePipe[file.id];
//       final lastValue = pipe.value;
//       // Make sure that the file we're sending is different from the last one
//       // that was going down this pipe.
//       if (lastValue != file) {
//         pipe.add(file);
//       }
//     }
//   }

//   // This is going to be a network call to:
//   // 'api/my/files' OR 'api/teams/[teamOwnerId]/files'
//   static void _loadDetails(Iterable<int> fileIds) async {
//     // Fake latency
//     await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(500)));

//     List<FileDetailsVM> downloadedFiles;
//     if (fileIds.contains(0)) {
//       downloadedFiles = [
//         FileDetailsVM(id: 0, ownerId: 16, name: 'First try!'),
//         FileDetailsVM(id: 1, ownerId: 16, name: 'Teddy Bear'),
//       ];
//     } else {
//       downloadedFiles = [
//         FileDetailsVM(id: 4, ownerId: 16, name: 'Secret Project'),
//         FileDetailsVM(id: 5, ownerId: 16, name: 'Spinning planets'),
//       ];
//     }
//     _updateFileDetails(downloadedFiles);
//   }
// }
