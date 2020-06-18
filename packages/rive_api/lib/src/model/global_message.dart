import 'package:flutter/material.dart';

class GlobalMessage {
  final String message;
  final String actionLabel;
  final VoidCallback callback;

  GlobalMessage(this.message, [this.actionLabel, this.callback]);
}
