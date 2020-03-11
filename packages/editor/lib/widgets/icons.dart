import 'package:flutter/material.dart';

import 'package:path_drawing/path_drawing.dart';

import 'package:rive_editor/widgets/theme.dart' show lightGrey;
import 'package:rive_editor/widgets/path_widget.dart';

/// Rive custom icon widgets

/// Folder icon SVG
final _folderIcon = parseSvgPathData(
  'M1.27621 1.94756L1.27642 1.94713C1.3976 1.7042 1.72809 1.5 '
  '2 1.5H7C7.27191 1.5 7.6024 1.7042 7.72358 1.94713L7.72379 '
  '1.94757L8.27563 3.05115C8.27589 3.05167 8.27615 3.05219 '
  '8.27641 3.05271C8.35844 3.21773 8.50314 3.32115 8.58162 '
  '3.36962C8.66055 3.41837 8.81718 3.50085 9 3.50085H13.5C14.0509 '
  '3.50085 14.5 3.94997 14.5 4.50073V12.5001C14.5 13.0509 14.0509 '
  '13.5 13.5 13.5H1.5C0.949106 13.5 0.5 13.0509 0.5 '
  '12.5001V4.00077C0.5 3.7266 0.600816 3.29921 0.723334 3.05322C0.723386 '
  '3.05312 0.723438 3.05302 0.72349 3.05291L1.27621 1.94756Z',
);

/// Standard widget builder for custom icons
class BaseIcon extends StatelessWidget {
  const BaseIcon(this.icon, {this.color = lightGrey, this.size = 13});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(icon, color: color, size: size);
}

class CloseIcon extends BaseIcon {
  const CloseIcon({Color color = lightGrey, double size = 13})
      : super(Icons.close, color: color, size: size);
}

class ProfileIcon extends BaseIcon {
  const ProfileIcon({Color color = lightGrey, double size = 13})
      : super(Icons.person_outline, color: color, size: size);
}

class SettingsIcon extends BaseIcon {
  const SettingsIcon({Color color = lightGrey, double size = 13})
      : super(Icons.settings, color: color, size: size);
}

class SearchIcon extends BaseIcon {
  const SearchIcon({Color color = lightGrey, double size = 13})
      : super(Icons.settings, color: color, size: size);
}

class AddIcon extends BaseIcon {
  const AddIcon({Color color = lightGrey, double size = 13})
      : super(Icons.add, color: color, size: size);
}

class ClockIcon extends BaseIcon {
  const ClockIcon({Color color = lightGrey, double size = 13})
      : super(Icons.timer, color: color, size: size);
}

class TrashIcon extends BaseIcon {
  const TrashIcon({Color color = lightGrey, double size = 13})
      : super(Icons.delete, color: color, size: size);
}

class FolderIcon extends StatelessWidget {
  const FolderIcon({this.color = lightGrey});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PathWidget(
      path: _folderIcon,
      nudge: const Offset(0, 0),
      paint: Paint()
        ..color = color
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );
  }
}
