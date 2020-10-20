import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:window_utils/window_utils.dart' as win_utils;
import 'package:rive_editor/external_url.dart';
import 'package:rive/rive.dart';

/// Widget shown when a castrophic error (unrecoverable) occurs.

class Catastrophe extends StatefulWidget {
  @override
  _CatastropheState createState() => _CatastropheState();
}

class _CatastropheState extends State<Catastrophe> {

  Artboard _riveArtboard;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/animations/crash.riv').then(
      (data) async {
        var file = RiveFile();
        var success = file.import(data);
        if (success) {
          var artboard = file.mainArtboard;
          artboard.addController(
            SimpleAnimation('idle')
          );
          setState(() => _riveArtboard = artboard);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => win_utils.startDrag(),
      child: Container(
        color: theme.colors.errorBackground,
        child: Row(
          children: [
            Expanded(flex: 1, child: Container()),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 340),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Oops,\nsomething went wrong!',
                    style: theme.textStyles.errorHeader),
                  const SizedBox(height: 10),
                  Text('Don’t worry, your work is saved in real-time.',
                    style: theme.textStyles.errorSubHeader),
                  const SizedBox(height: 20),
                  Text('Our team has been notified and is'
                    '\nlooking into the cause.',
                    style: theme.textStyles.errorCaption),
                  const SizedBox(height: 10),
                  Text('Please restart to continue using Rive.',
                    style: theme.textStyles.errorCaption),
                  const SizedBox(height: 30),
                  FeedbackButton()
                ]
              ),
            ),
            Expanded(
              flex: 4,
              child: _riveArtboard == null
                ? const  SizedBox()
                : Rive(
                    artboard: _riveArtboard,
                    fit: BoxFit.contain,
                    alignment: Alignment.center
                ),
            )
          ]
        )
      ),
    );
  }
}

class FeedbackButton extends StatefulWidget {
  @override
  _FeedbackButtonState createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {

  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: launchSupportUrl,
        child: SizedBox(
          width: 140,
          height: 35,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              color: _isHovered
                ? theme.colors.getWhite
                : theme.colors.textButtonLight,
              borderRadius: BorderRadius.circular(17.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    _isHovered ? 0.8 : 0.6),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: Offset(0, _isHovered ? 8 : 6),
              )]
            ),
            child: Center(
              child: Text('Send feedback',
                style: theme.textStyles.errorAction)),
          )
        )
      ),
    );
  }
}