import 'package:flutter/material.dart';
import 'package:rive_editor/rive/connected_users/user.dart';
import 'package:rive_editor/rive/rive.dart';

class ConnectedUsers extends StatelessWidget {
  final Rive rive;

  const ConnectedUsers({
    Key key,
    @required this.rive,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ConnectedUser>>(
      valueListenable: rive.conntectedUsers.users,
      builder: (context, users, child) {
        print("New Items... ${users.length}");
        return Row(
          children: [
            for (var connectedUser in users) ...[
              AvatarView(
                color: Color(connectedUser.colorValue),
                imageUrl: connectedUser.user.avatar,
              ),
              child,
            ],
          ],
        );
      },
      child: Container(width: 20.0),
    );
  }
}

class AvatarView extends StatelessWidget {
  final String imageUrl;
  final Color color;

  const AvatarView({
    Key key,
    @required this.imageUrl,
    @required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const kRadius = 30.0;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return Center(
      child: SizedBox(
        width: kRadius,
        height: kRadius,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(kRadius / 2),
          ),
          child: CircleAvatar(
            child: hasImage ? null : Center(child: Icon(Icons.person)),
            backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
          ),
        ),
      ),
    );
  }
}
