import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive_file.dart';
import 'package:rive/rive_renderer.dart';
import 'package:rive/controllers/simple_controller.dart';
import 'package:rive/rive_core/rive_animation_controller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _togglePlay() {
    setState(() => _controller.isActive = !_controller.isActive);
  }

  RiveFile _rive;
  RiveAnimationController _controller;
  @override
  void initState() {
    super.initState();

    rootBundle.load('assets/draworderanimation_3.riv').then(
      (data) async {
        var file = RiveFile();
        var success = file.import(data);
        if (success) {
          file.mainArtboard.addController(
            _controller = SimpleAnimation('DrawOrder'),
          );
          setState(() => _rive = file);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _rive == null
            ? const SizedBox()
            : RiveRenderer(artboard: _rive.mainArtboard),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _togglePlay,
        tooltip: _controller?.isActive ?? false ? 'Pause' : 'Play',
        child: Icon(
          _controller?.isActive ?? false ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}
