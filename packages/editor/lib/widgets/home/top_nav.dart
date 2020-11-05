import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';

class TopNav extends StatelessWidget {
  final CurrentDirectory currentDirectory;

  Owner get owner => currentDirectory.owner;

  const TopNav(this.currentDirectory, {Key key}) : super(key: key);

  Widget _navControls(BuildContext context, List<Folder> folders) {
    final riveColors = RiveTheme.of(context).colors;
    final styles = RiveTheme.of(context).textStyles;
    final children = <Widget>[];
    final currentFolder = folders.firstWhere(
        (folder) => folder.id == currentDirectory.folder?.id,
        orElse: () => null);

    // Current folder could not be found if the folders list is from a
    // previously selected owner and the currentDirectory is pointing to a
    // folder in a new owner set.
    if (currentFolder == null) {
      // TODO: consider fixing this by moving the state of the top nav to some
      // manager and having a synced viewmodel get sent down to it.
      return const SizedBox();
    }

    if (currentFolder.isRoot) {
      children.add(
        AvatarView(
          diameter: 30,
          borderWidth: 0,
          imageUrl: owner.avatarUrl,
          name: owner.displayName,
          color: StageCursor.colorFromPalette(owner.ownerId),
        ),
      );
      children.add(const SizedBox(width: 9));
      children.add(Text(owner.displayName, style: styles.fileGreyTextLarge));
    } else {
      children.add(
        Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: riveColors.fileBackgroundLightGrey,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: TintedIcon(
                      icon: PackedIcon.back,
                      color: riveColors.inspectorTextColor,
                    ),
                  ),
                ),
                // if the current folder has no parent, just take you back to
                // the magic folder nbr 1. (this deals with the Deleted folder
                // anomaly)
                onTap: () {
                  FileManager().loadParentFolder(currentDirectory);
                }),
          ),
        ),
      );
      children.add(const SizedBox(width: 9));
      children.add(Text(currentFolder.name, style: styles.fileGreyTextLarge));
    }
    children.add(const Spacer());
    children.add(PopupButton<PopupContextItem>(
      direction: PopupDirection.bottomToLeft,
      builder: (popupContext) {
        return const SizedBox(
          width: 29,
          height: 29,
          child: PlusIcon(),
        );
      },
      itemBuilder: (popupContext, item, isHovered) =>
          item.itemBuilder(popupContext, isHovered),
      itemsBuilder: (context) => [
        PopupContextItem(
          'New File',
          select: () async {
            final createdFile = await FileManager().createFile(
              owner,
              currentDirectory.folder,
            );

            await FileManager().loadFolders(owner);
            Plumber().message(currentDirectory);
            await RiveContext.of(context).open(createdFile);
          },
        ),
        PopupContextItem(
          'New Folder',
          select: () async {
            await FileManager().createFolder(owner, currentDirectory.folder);
            await FileManager().loadFolders(owner);
            Plumber().message(currentDirectory);
          },
        ),
      ],
    ));

    return Row(children: children);
  }

  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;

    return Underline(
      color: riveColors.fileLineGrey,
      child: ValueStreamBuilder<List<Folder>>(
        stream:
            Plumber().getStream<List<Folder>>(currentDirectory.owner.hashCode),
        builder: (context, snapshot) => snapshot.hasData == false
            ? const SizedBox()
            : _navControls(context, snapshot.data),
      ),
      thickness: 1,
    );
  }
}

/// A plus icon that uses a custom painter.
/// Using a tinted icon here causes the icon
/// to swim. Painter gets around that.
class PlusIcon extends StatelessWidget {
  const PlusIcon({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final riveColors = RiveTheme.of(context).colors;
    return Container(
      decoration: BoxDecoration(
        color: riveColors.commonDarkGrey,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 15,
          height: 15,
          child: CustomPaint(
            painter: PlusIconPainter(),
          ),
        ),
      ),
    );
  }
}

/// A custom paintor to paint a cross
class PlusIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const color = Color(0xFFFFFFFF);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 2, 0 + 0.5),
      Offset(size.width / 2, size.height + 0.5),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2 + 0.5),
      Offset(size.width, size.height / 2 + 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(PlusIconPainter oldDelegate) => false;
}
