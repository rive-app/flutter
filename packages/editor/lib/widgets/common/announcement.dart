import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class AnnouncementAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return SizedBox(
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [theme.colors.accentMagenta, Colors.amber]),
          shape: BoxShape.circle,
        ),
        child: Center(child: Text('!', style: theme.textStyles.fileWhiteText)),
      ),
    );
  }
}
