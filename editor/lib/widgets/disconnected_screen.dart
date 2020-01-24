import 'package:flutter/material.dart';

/// Widget shown when the internet is required and currently not available.
/// TODO: Figure out design for this.
class DisconnectedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: const Text(
            "Internet currently unavailable, will retry..."),
      ),
    );
  }
}
