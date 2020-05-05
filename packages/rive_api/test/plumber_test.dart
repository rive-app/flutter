void main() {}
// import 'dart:async';

// import 'package:rive_api/src/manager/current_directory.dart';
// import 'package:rive_api/src/manager/folder_contents.dart';
// import 'package:rive_api/src/manager/team.dart';
// import 'package:rive_api/src/plumber.dart';
// import 'package:rive_api/src/view_model/view_model.dart';
// import 'package:test/test.dart';
// void main() {
//   Plumber plumber;

//   setUp(() {
//     plumber = Plumber();
//   });

//   group('Plumber', () {
//     test('Init the Current Directory to Top Folder', () async {
//       final c = Completer();

//       final stream = plumber.getStream<CurrentDirectoryVM>();

//       CurrentDirectoryManager.setDirectory(0);

//       var subscription = stream.listen((event) {
//         print("Just received this event: $event");
//         expect(event.id, 0);
//         c.complete();
//       });

//       await c.future;
//       subscription.cancel();
//     });

//     test('A new folder is active: get the new contents', () async {
//       final c = Completer();
//       final c1 = Completer();
//       // Instantiate the directory to the top level directory.
//       CurrentDirectoryManager.setDirectory(0);
//       // This manager listens for Current Directory¸ info, and it loads the relative files & folders.
//       var manager = FolderContentsManager();

//       final stream = plumber.getStream<FolderContentsVM>();

//       var subscription = stream.listen((folderContents) {
//         expect(folderContents.files, isNotEmpty);
//         expect(folderContents.folders, isNotEmpty);
//         if (folderContents.folders.length > 1) {
//           print("Completing the first tranche!");
//           c.complete();
//         } else {
//           print('Done with the new folder too!');
//           c1.complete();
//         }
//       });

//       await c.future;

//       // I click on the interface, triggering a change in the current directory.
//       print('Click');
//       plumber.message(CurrentDirectoryVM(1, 'Ooof'));

//       await c1.future;

//       subscription.cancel();
//       // Clean up subscriptions.
//       manager.dispose();
//     });

//     test('Reload the list of teams', () async {
//       final c = Completer();
//       // Setup.
//       final stream = plumber.getStream<TeamList>();
//       TeamListManager.getTeams(0);

//       var subscription = stream.listen((teamList) {
//         expect(teamList.teams, isNotEmpty);
//         expect(teamList.teams[0].id, 2);
//         c.complete();
//       });

//       await c.future;

//       subscription.cancel();
//     });

//     test('Load Folder Contents & receive details in a two-step process',
//         () async {
//       final c = Completer();
//       List<StreamSubscription> fileDetailsSubs = [];

//       // Instantiate the directory to the top level directory.
//       CurrentDirectoryManager.setDirectory(0);
//       // This manager listens for Current Directory¸ info, and it loads the relative files & folders.
//       var manager = FolderContentsManager();

//       final stream = plumber.getStream<FolderContentsVM>();

//       var contentsSub = stream.listen((contents) {
//         for (final filePipe in contents.files) {
//           var fileSub = filePipe.listen((value) {
//             print("This is my new file: $value");
//             if (value.id == 1 && value.name != null) {
//               c.complete();
//             }
//           });
//           fileDetailsSubs.add(fileSub);
//         }
//       });

//       await c.future;

//       contentsSub.cancel();
//       for (final subs in fileDetailsSubs) {
//         subs.cancel();
//       }
//       manager.dispose();
//     });
//   });
// }
