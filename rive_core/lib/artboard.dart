import 'src/generated/artboard_base.dart';
export 'src/generated/artboard_base.dart';

abstract class ArtboardDelegate {
  void markBoundsDirty();
}

class Artboard extends ArtboardBase {
  ArtboardDelegate _delegate;

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is ArtboardDelegate) {
      _delegate = to;
    }
  }

  @override
  void widthChanged(double from, double to) {
    super.widthChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void heightChanged(double from, double to) {
    super.heightChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void yChanged(double from, double to) {
    super.yChanged(from, to);
    _delegate?.markBoundsDirty();
  }
}
