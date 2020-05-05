import 'package:admin/impersonate.dart';
import 'package:admin/signout.dart';
import 'package:flutter/material.dart';

class AdminView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Impersonate(),
            Signout(),
          ],
        ),
      ),
    );
  }
}