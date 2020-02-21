import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive_api/user.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/rive.dart';

class ConnectedUsers extends StatelessWidget {
  final Rive rive;

  const ConnectedUsers({
    Key key,
    @required this.rive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RiveFile>(
      valueListenable: rive.file,
      builder: (_, file, __) =>
          ValueListenableBuilder<Iterable<ClientSidePlayer>>(
        valueListenable: file.allPlayers,
        builder: (context, users, child) {
          print("Connected Users: ${users.length}");
          return Row(
            children: [
              for (var connectedUser in users) ...[
                ValueListenableBuilder<RiveUser>(
                  valueListenable: connectedUser.user,
                  builder: (_, user, __) => AvatarView(
                    color: Color(_getRandomColor()),
                    imageUrl: user.avatar,
                  ),
                ),
                child,
              ],
            ],
          );
        },
        child: Container(width: 20.0),
      ),
    );
  }
}

int _getRandomColor() {
  final random = Random();
  final _lerp = random.nextDouble();
  final _color = Color.lerp(Colors.red, Colors.blue, _lerp);
  return _color.value;
}

/// Generates a random integer where [from] <= [to].
int randomBetween(int from, int to) {
  final random = Random();
  if (from > to) throw Exception('$from cannot be > $to');
  double randomDouble = random.nextDouble();
  if (randomDouble < 0) randomDouble *= -1;
  if (randomDouble > 1) randomDouble = 1 / randomDouble;
  return ((to - from) * random.nextDouble()).toInt() + from;
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
