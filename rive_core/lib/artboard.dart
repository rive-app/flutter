import 'src/generated/artboard_base.dart';
export 'src/generated/artboard_base.dart';

abstract class ArtboardDelegate {
  void markBoundsDirty();
}

class Artboard extends ArtboardBase {
  ArtboardDelegate delegate;

  @override
  void widthChanged(double from, double to) {
    super.widthChanged(from, to);
    delegate?.markBoundsDirty();

  }
}
