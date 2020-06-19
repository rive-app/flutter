import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive_file.dart';
import 'package:rive/rive_renderer.dart';
import 'package:rive/controllers/simple_controller.dart';

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
        if (success) {
          file.mainArtboard.addController(
            SimpleAnimation('Untitled 1'),
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
        : RiveRenderer(artboard: _rive.mainArtboard, fit: widget.fit);
  }
}
