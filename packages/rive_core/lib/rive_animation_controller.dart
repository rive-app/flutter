import 'package:flutter/material.dart';

abstract class RiveAnimationController with ChangeNotifier {
  bool advance(double elapsedSeconds);
}
