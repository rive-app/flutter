import 'package:flutter/material.dart';

class ThemeUtils {
  ThemeUtils._();
  static const Color backgroundLightGrey = Color.fromRGBO(241, 241, 241, 1);
  static const Color backgroundDarkGrey = Color.fromRGBO(102, 102, 102, 1);
  static const Color textGrey = Color.fromRGBO(51, 51, 51, 1);
  static const Color iconColor = Color.fromRGBO(0, 0, 0, 0.3);
  static const Color buttonColor = Color.fromRGBO(0, 0, 0, 0.1);
  static const Color buttonTextColor = Color.fromRGBO(136, 136, 136, 1);
  static const Color selectedBlue = Color.fromRGBO(87, 165, 224, 1.0);
  static const Color lineGrey = Color.fromRGBO(216, 216, 216, 1.0);
}

class RiveIcons {
  static Widget close([Color color = Colors.white, double size]) {
    return Icon(Icons.close, color: color, size: size);
  }

  static Widget trash([Color color = Colors.white, double size]) {
    return Icon(Icons.delete, color: color, size: size);
  }

  static Widget folder([Color color = Colors.white, double size]) {
    return Icon(Icons.folder_open, color: color, size: size);
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
