import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/owner.dart';

import 'package:rive_api/models/team.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:rive_editor/widgets/tree_view/tree_expander.dart';

import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_style.dart';
import 'package:tree_widget/tree_widget.dart';

/// Builds a TreeView styled for folders.
class FolderTreeView extends StatelessWidget {
  final FolderTreeController controller;
  final TreeStyle style;

  const FolderTreeView({
    @required this.controller,
    this.style,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final fileBrowser = RiveContext.of(context).activeFileBrowser.value;
    return TreeView<RiveFolder>(
      style: style,
      controller: controller,
      expanderBuilder: (context, item, style) => Container(
        child: Center(
          child: TreeExpander(
            key: item.key,
            iconColor: fileBrowser?.selectedFolder == item.data
                ? Colors.white
                : colors.fileUnselectedFolderIcon,
            isExpanded: item.isExpanded,
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: fileBrowser?.selectedFolder == item.data
                ? colors.selectedTreeLines
                : colors.filesTreeStroke,
            width: 1.0,
            style: BorderStyle.solid,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(7.5),
          ),
        ),
      ),
      iconBuilder: (context, item, style) => Container(
        width: 15,
        height: 15,
        child: Center(
          child: TreeRowIcon(item: item, fileBrowser: fileBrowser),
        ),
      ),
      extraBuilder: (context, item, index) => Container(),
      backgroundBuilder: (context, item, style) =>
          ValueListenableBuilder<SelectionState>(
        valueListenable: item.data.selectionState,
        builder: (context, selectionState, _) {
          // NOTE: selectionstate gets a bit confused here
          // the tree and file browser are sharing items
          // which means they share selection state, which
          // isnt always what we want
          var _selectionState = SelectionState.none;
          if (fileBrowser?.selectedFolder == item.data) {
            _selectionState = SelectionState.selected;
          } else if (selectionState == SelectionState.hovered) {
            _selectionState = SelectionState.hovered;
          }
          return DropItemBackground(DropState.none, _selectionState);
        },
      ),
      itemBuilder: (context, item, style) => Expanded(
        child: Container(
          child: IgnorePointer(
            child: Text(
              item.data.displayName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: fileBrowser?.selectedFolder == item.data
                    ? Colors.white
                    : colors.fileTreeText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TreeRowIcon extends StatelessWidget {
  const TreeRowIcon({
    @required this.item,
    @required this.fileBrowser,
    Key key,
  }) : super(key: key);

  final FlatTreeItem<RiveFolder> item;
  final FileBrowser fileBrowser;

  @override
  Widget build(BuildContext context) {
    return RiveFolderIcon(
      folder: item.data,
      selected: fileBrowser?.selectedFolder == item.data,
    );
  }
}

class RiveFolderIcon extends StatelessWidget {
  const RiveFolderIcon({
    @required this.folder,
    @required this.selected,
    Key key,
  }) : super(key: key);

  final RiveFolder folder;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    var colors = RiveTheme.of(context).colors;
    if (folder.owner != null) {
      return SizedAvatar(
        owner: folder.owner,
        selected: selected,
      );
    } else {
      return TintedIcon(
        icon: 'folder',
        color: selected
            ? colors.fileSelectedFolderIcon
            : colors.fileUnselectedFolderIcon,
      );
    }
  }
}

class SizedAvatar extends StatelessWidget {
  const SizedAvatar({
    @required this.owner,
    this.selected = false,
    this.size = const Size(20, 20),
    this.teamIcon = 'teams',
    this.userIcon = 'your-files',
    this.addBackground = false,
    Key key,
  }) : super(key: key);

  final RiveOwner owner;
  final Size size;
  final bool selected;
  final bool addBackground;
  final String teamIcon;
  final String userIcon;

  Widget _backupIcon(RiveColors colors) {
    return TintedIcon(
      icon: (owner is RiveTeam) ? teamIcon : userIcon,
      color: selected
          ? colors.fileSelectedFolderIcon
          : colors.fileUnselectedFolderIcon,
    );
  }

  Widget _backupIconWithBackground(RiveColors colors) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
                color: colors.fileBackgroundLightGrey,
                shape: BoxShape.circle,
                border: Border.all(
                    color: colors.fileUnselectedFolderIcon, width: 1)),
          ),
        ),
        Center(child: _backupIcon(colors)),
      ],
    );
  }

  Widget _networkImage(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: ImageCacheProvider.of(context).loadRawImageFromUrl(owner.avatar),
      builder: (context, snapshot) => CircleAvatar(
        backgroundColor: Colors.transparent,
        // backgroundImage: NetworkImage(item.data.owner?.avatar),
        backgroundImage: snapshot.hasData ? MemoryImage(snapshot.data) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget _avatarChild;
    var colors = RiveTheme.of(context).colors;

    if (owner.avatar == null && addBackground) {
      _avatarChild = _backupIconWithBackground(colors);
    } else if (owner.avatar == null) {
      _avatarChild = _backupIcon(colors);
    } else {
      _avatarChild = _networkImage(context);
    }
    return Center(
        child: SizedBox(
      width: size.width,
      height: size.height,
      child: _avatarChild,
    ));
  }
}
