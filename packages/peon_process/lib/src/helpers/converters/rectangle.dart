import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/rectangle.dart';

class RectangleConverter extends ParametricPathConverter {
  RectangleConverter(
    RectangleBase ellipse,
    RiveFile file,
    ContainerComponent maybeParent,
  ) : super(ellipse, file, maybeParent);

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    final cornerRadius = jsonData['cornerRadius'];

    final rectangle = component as RectangleBase;

    if (cornerRadius is num && cornerRadius != 0) {
      rectangle.cornerRadius = cornerRadius.toDouble();
    }
  }
}
