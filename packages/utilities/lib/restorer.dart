/// General subscription/tracker for things that need to be restored.
// ignore: one_member_abstracts
abstract class Restorer {
  bool restore();
}

class RestoreCallback implements Restorer {
  bool Function() _restore;
  RestoreCallback(this._restore);

  @override
  bool restore() {
    // Protects against multiple calls.
    var r = _restore;
    _restore = null;
    return r?.call() ?? false;
  }
}
