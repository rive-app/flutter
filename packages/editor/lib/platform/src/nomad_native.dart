import 'package:rive_editor/platform/nomad.dart';

class NomadNative extends Nomad {
  final List<Trip> _log = [];
  int _logIndex = 0;

  @override
  bool makeFirstTrip() => false;

  @override
  Trip travel(String path, {String title, bool replace = false}) {
    var trip = super.travel(path, title: title, replace: replace);
    if (trip == null) {
      return null;
    }

    // Add it to the log
    var index = _logIndex;
    if (replace) {
      index -= 1;
    }
    _log.removeRange(index, _log.length);
    _log.add(trip);
    _logIndex = _log.length;

    internalTravel(trip);

    return trip;
  }

  @override
  void go(int steps) {

    var index = _logIndex + steps - 1;
    if (index >= 0 && index < _log.length) {
      _logIndex = index;
      var trip = _log[_logIndex];
      _logIndex++;
      internalTravel(trip);
    }
  }
}

Nomad makeNomad() => NomadNative();