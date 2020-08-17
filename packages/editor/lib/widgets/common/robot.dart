import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive/rive.dart';

const cleanerLocation = 'assets/animations/robot_cleaner_transparent.riv';

class Robot extends StatefulWidget {
  final BoxFit fit;

  const Robot({
    Key key,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  _RobotState createState() => _RobotState();
}

class _RobotState extends State<Robot> {
  RiveFile _rive;
  @override
  void initState() {
    super.initState();

    rootBundle.load(cleanerLocation).then(
      (data) async {
        var file = RiveFile();
        var success = file.import(data);
        if (success) {
          file.mainArtboard.addController(
            SimpleAnimation('dust_fly'),
          );
          file.mainArtboard.addController(
            SimpleAnimation('Test'),
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
