import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class FileBrowserStream extends StatelessWidget {
  FileBrowserStream() {
    // TODO: remove this.
    UserManager().loadMe();
    FolderContentsManager();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FolderContents>(
        stream: Plumber().getStream<FolderContents>(),
        builder: (_, snapshot) {
          final widgets = <Widget>[];
          if (snapshot.hasData) {
            final contents = snapshot.data;
            for (final folder in contents.folders) {
              widgets.add(
                Text('Folder: ${folder.id} - ${folder.name}'),
              );
            }
            // Add files.
            for (final file in contents.files) {
              widgets.add(
                Text('File: ${file.id}'),
              );
            }
          }
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(30),
            children: widgets,
          );
        });
  }
}
