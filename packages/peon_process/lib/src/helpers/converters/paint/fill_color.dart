import 'package:peon_process/converters.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_core/shapes/paint/fill.dart';

class FillColorConverter extends FillBaseConverter with ColorExtractor {
  FillColorConverter(
    Fill component,
    RiveFile context,
    ContainerComponent maybeParent,
  ) : super(component, context, maybeParent);

  /// From [ColorExtractor]
  @override
  Fill get paint => component as Fill;

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    extractColor(jsonData);
  }
}

class FillGradientConverter extends FillBaseConverter with ColorExtractor {
  FillGradientConverter(
      FillBase component, RiveFile context, ContainerComponent maybeParent)
      : super(component, context, maybeParent);

  /// From [ColorExtractor]
  @override
  FillBase get paint => component as FillBase;

  @override
  void deserialize(Map<String, Object> jsonData) {
    super.deserialize(jsonData);
    extractGradient(jsonData);
  }
}
