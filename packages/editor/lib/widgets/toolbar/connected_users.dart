import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ConnectedUsers extends StatelessWidget {
  final Rive rive;

  const ConnectedUsers({
    @required this.rive,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<OpenFileContext>(
      valueListenable: rive.file,
      builder: (context, file, _) =>
          ValueListenableBuilder<Iterable<ClientSidePlayer>>(
        valueListenable: file.core.allPlayers,
        builder: (context, users, _) {
          return Row(
            children: [
              for (var connectedUser in users) ...[
                ValueListenableBuilder<RiveUser>(
                  valueListenable: connectedUser.userNotifier,
                  builder: (context, user, chld) => AvatarView(
                    color: StageCursor.colorFromPalette(connectedUser.index),
                    imageUrl: user?.avatar,
                    name: user?.name ?? user?.username,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AvatarView extends StatelessWidget {
  const AvatarView({
    @required this.imageUrl,
    @required this.color,
    @required this.name,
    Key key,
    this.diameter = 26,
    this.borderWidth = 2,
  }) : super(key: key);

  final String imageUrl;
  final Color color;
  final String name;
  final double diameter;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    final hasName = name != null && name.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Container(
            decoration: BoxDecoration(
              color: imageUrl == null ? color : null,
              border: Border.all(color: color, width: borderWidth),
              borderRadius: BorderRadius.circular(diameter / 2),
            ),
            padding: const EdgeInsets.all(1),
            child: hasImage
                ? FutureBuilder<Uint8List>(
                    future: ImageCacheProvider.of(context)
                        .loadRawImageFromUrl(imageUrl),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        backgroundImage: snapshot.hasData
                            ? MemoryImage(snapshot.data)
                            : null,
                      );
                    })
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Text(
                        hasName ? name.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: diameter / 2,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
