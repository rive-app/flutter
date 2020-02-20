import 'package:flutter/material.dart';

class ConnectedUsers extends StatefulWidget {
  @override
  _ConnectedUsersState createState() => _ConnectedUsersState();
}

class _ConnectedUsersState extends State<ConnectedUsers> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          AvatarView(
            color: Colors.red,
            imageUrl: '',
          ),
          Container(width: 20.0),
          AvatarView(
            color: Colors.blue,
            imageUrl: '',
          ),
          Container(width: 20.0),
          AvatarView(
            color: Colors.yellow,
            imageUrl: '',
          ),
        ],
      ),
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
