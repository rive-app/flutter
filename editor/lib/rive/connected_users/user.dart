import 'package:flutter/material.dart';
import 'package:rive_api/user.dart';

// ignore_for_file: argument_type_not_assignable,implicit_dynamic_map_literal

class ConnectedUser {
  final RiveUser user;
  double cursorX;
  double cursorY;
  int colorValue;

  ConnectedUser({
    @required this.user,
    this.cursorX,
    this.cursorY,
    this.colorValue,
  });
}
