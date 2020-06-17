/// General subscription/tracker for things that need to be restored.
class Restorer {
  bool Function() _restore;
  Restorer(this._restore);

  bool restore() {
    // Protects against multiple calls.
    var r = _restore;
    _restore = null;
    return r?.call() ?? false;
  }
}
