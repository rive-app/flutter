import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:rive_editor/widgets/path_widget.dart';

class ThemeUtils {
  ThemeUtils._();
  static const Color backgroundLightGrey = Color.fromRGBO(241, 241, 241, 1);
  static const Color backgroundDarkGrey = Color.fromRGBO(102, 102, 102, 1);
  static const Color textGrey = Color.fromRGBO(51, 51, 51, 1);
  static const Color textLightGrey = Color.fromRGBO(102, 102, 102, 1);
  static const Color iconColor = Color.fromRGBO(169, 169, 169, 1.0);
  static const Color buttonColor = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color buttonTextColor = Color.fromRGBO(136, 136, 136, 1);
  static const Color selectedBlue = Color.fromRGBO(87, 165, 224, 1.0);
  static const Color lineGrey = Color.fromRGBO(216, 216, 216, 1.0);
}


var folderIcon = parseSvgPathData(
    'M1.27621 1.94756L1.27642 1.94713C1.3976 1.7042 1.72809 1.5 2 1.5H7C7.27191 1.5 7.6024 1.7042 7.72358 1.94713L7.72379 1.94757L8.27563 3.05115C8.27589 3.05167 8.27615 3.05219 8.27641 3.05271C8.35844 3.21773 8.50314 3.32115 8.58162 3.36962C8.66055 3.41837 8.81718 3.50085 9 3.50085H13.5C14.0509 3.50085 14.5 3.94997 14.5 4.50073V12.5001C14.5 13.0509 14.0509 13.5 13.5 13.5H1.5C0.949106 13.5 0.5 13.0509 0.5 12.5001V4.00077C0.5 3.7266 0.600816 3.29921 0.723334 3.05322C0.723386 3.05312 0.723438 3.05302 0.72349 3.05291L1.27621 1.94756Z');


class RiveIcons {
  static Widget close([Color color = Colors.white, double size]) {
    return Icon(Icons.close, color: color, size: size);
  }

  static Widget trash([Color color = Colors.white, double size]) {
    return Icon(Icons.delete, color: color, size: size);
  }

  static Widget folder([Color color = Colors.white, double size]) {
    // return Icon(Icons.folder_open, color: color, size: size);

    return PathWidget(
                    path: folderIcon,
                    nudge: const Offset(0.0, 0),
                    paint: Paint()
                      ..color = color
                      ..strokeWidth = 1
                      ..style = PaintingStyle.stroke
                      ..isAntiAlias = true,
                  );
  }

  static Widget settings([Color color = Colors.white, double size]) {
    return Icon(Icons.settings, color: color, size: size);
  }

  static Widget clock([Color color = Colors.white, double size]) {
    return Icon(Icons.timer, color: color, size: size);
  }

  static Widget profile([Color color = Colors.white, double size]) {
    return Icon(Icons.person_outline, color: color, size: size);
  }

  static Widget add([Color color = Colors.white, double size]) {
    return Icon(Icons.add, color: color, size: size);
  }

  static Widget search([Color color = Colors.white, double size]) {
    return Icon(Icons.search, color: color, size: size);
  }
}
