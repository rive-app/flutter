import 'package:flutter/material.dart';

/// Widget shown when a castrophic error (unrecoverable) occurs.
/// TODO: Figure out design for this.
class Catastrophe extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: const Text(
            "Catastrophic Error: App cannot recover. Please restart"),
      ),
    );
  }
}
