import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:utilities/utilities.dart';

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
              for (var connectedUser in users)
                ValueListenableBuilder<RiveUser>(
                  valueListenable: connectedUser.userNotifier,
                  builder: (context, user, chld) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AvatarView(
                      color: StageCursor.colorFromPalette(connectedUser.index),
                      imageUrl: user?.avatar,
                      name: user?.name ?? user?.username,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AvatarView extends StatefulWidget {
  const AvatarView({
    @required this.imageUrl,
    @required this.color,
    @required this.name,
    Key key,
    this.diameter = 26,
    this.borderWidth = 2,
    // this.padding = 10,
  }) : super(key: key);

  final String imageUrl;
  final Color color;
  final String name;
  final double diameter;
  final double borderWidth;
  // final double padding;

  @override
  _AvatarViewState createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  bool _avatarImageFailed = false;

  @override
  Widget build(BuildContext context) {
    var renderDiameter =
        widget.diameter % 2 == 0 ? widget.diameter + 1 : widget.diameter;
    final hasImage = !_avatarImageFailed &&
        widget.imageUrl != null &&
        widget.imageUrl.isNotEmpty;
    final hasName = widget.name != null && widget.name.isNotEmpty;
    final darkFont = useDarkContrast(
        widget.color.red, widget.color.green, widget.color.blue);

    return Center(
      child: Container(
        width: renderDiameter,
        height: renderDiameter,
        decoration: BoxDecoration(
          color: !hasImage ? widget.color : null,
          border: (widget.borderWidth == 0)
              ? null
              : Border.all(color: widget.color, width: widget.borderWidth),
          borderRadius: BorderRadius.circular(renderDiameter / 2),
        ),
        padding: widget.borderWidth != 0 && hasImage
            ? const EdgeInsets.all(1)
            : null,
        child: hasImage
            ? CachedCircleAvatar(
                widget.imageUrl,
                diameter: renderDiameter,
                onImageError: () {
                  if (!mounted) {
                    return;
                  }
                  setState(
                    () {
                      _avatarImageFailed = true;
                    },
                  );
                },
              )
            : Center(
                child: Text(
                  hasName ? widget.name.substring(0, 1).toUpperCase() : '?',
                  textAlign: TextAlign.center,
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                  style: RiveTheme.of(context).textStyles.basic.copyWith(
                        fontFamily: 'Roboto-Light',
                        fontSize: renderDiameter * 0.65,
                        color: darkFont
                            ? const Color(0xFF000000)
                            : const Color(0xFFFFFFFF),
                      ),
                ),
              ),
      ),
    );
  }
}
