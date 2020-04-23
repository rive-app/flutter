import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for frame time values (HH:MM:SS:FF).
class TimeCodeValueConverter extends InputValueConverter<int> {
  final int fps;
  TimeCodeValueConverter(this.fps);

  @override
  int fromEditingValue(String value) {
    var parts = value.split(":");
    if (parts.isEmpty || parts.length == 1) {
      return double.parse(value).round();
    } else if (parts.length == 2) {
      var seconds = double.parse(parts[0]).round();
      var frames = double.parse(parts[1]).round();
      return seconds * fps + frames;
    } else {
      var minutes = double.parse(parts[0]).round();
      var seconds = double.parse(parts[1]).round();
      var frames = double.parse(parts[2]).round();
      return minutes * 60 * fps + seconds * fps + frames;
    }
  }

  @override
  String toEditingValue(int value) {
    double seconds = value / fps;
    int minutes = (seconds / 60).floor();
    int wholeSeconds = (seconds - minutes * 60).floor();
    int frames = value - (wholeSeconds + minutes * 60) * fps;
    return minutes.toString().padLeft(2, '0') +
        ':' +
        wholeSeconds.toString().padLeft(2, '0') +
        ':' +
        frames.toString().padLeft(2, '0');
  }

  static final TimeCodeValueConverter instance = TimeCodeValueConverter(2);

  @override
  int drag(int value, double amount) => (value ?? 1) - amount.round();
}