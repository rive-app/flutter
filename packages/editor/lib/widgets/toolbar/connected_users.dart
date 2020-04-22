import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';

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
      builder: (_, file, __) =>
          ValueListenableBuilder<Iterable<ClientSidePlayer>>(
        valueListenable: file.core.allPlayers,
        builder: (context, users, child) {
          // print("Connected Users: ${users.length}");
          return Row(
            children: [
              for (var connectedUser in users) ...[
                ValueListenableBuilder<RiveUser>(
                  valueListenable: connectedUser.userNotifier,
                  builder: (context, user, chld) => AvatarView(
                    color: StageCursor.colorFromPalette(connectedUser.index),
                    imageUrl: user?.avatar,
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
  final String imageUrl;
  final Color color;
  final double diameter;
  final double borderWidth;

  const AvatarView({
    @required this.imageUrl,
    @required this.color,
    Key key,
    this.diameter = 26,
    this.borderWidth = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal:10),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: color, width: borderWidth),
              borderRadius: BorderRadius.circular(diameter / 2),
            ),
            padding: const EdgeInsets.all(1.0),
            child: CircleAvatar(
              child: hasImage
                  ? null
                  : Center(
                      child: Icon(
                        Icons.person,
                        size: diameter,
                      ),
                    ),
              backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
            ),
          ),
        ),
      ),
    );
  }
}
