import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

const _animationFiles = [
  'ping_pong.riv',
  'web_&_desktop_2.riv',
];

class FMA extends StatefulWidget {
  final BoxFit fit;

  const FMA({
    Key key,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  _FMAState createState() => _FMAState();
}

class _FMAState extends State<FMA> {
  RiveFile _rive;
  @override
  void initState() {
    super.initState();

    var rand = Random();
    var filename = _animationFiles[rand.nextInt(_animationFiles.length)];
    rootBundle.load('assets/animations/$filename').then(
      (data) async {
        var file = RiveFile();
        var success = file.import(data);
        if (success && file.mainArtboard.animations.isNotEmpty) {
          file.mainArtboard.addController(
            SimpleAnimation(file.mainArtboard.animations.first.name),
          );
          setState(() => _rive = file);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _rive == null
        ? const SizedBox()
        : Rive(artboard: _rive.mainArtboard, fit: widget.fit);
  }
}
