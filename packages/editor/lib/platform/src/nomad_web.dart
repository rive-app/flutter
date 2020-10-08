import 'dart:js' as js;

import 'package:rive_editor/platform/nomad.dart';

class NomadWeb extends Nomad {
  @override
  bool makeFirstTrip() {
    var location = (js.context['getLocation'] as js.JsFunction)
        .apply(<dynamic>[]) as String;
    js.context['travel'] = (String path) {
      var trip = super.travel(path);
      if (trip == null) {
        return false;
      }
      trip.route.travel(trip);
    };

    var trip = super.travel(location);
    if (trip != null) {
      trip.route.travel(trip);
      return true;
    }
    return false;
  }

  @override
  Trip travel(String path, {String title, bool replace = false}) {
    var trip = super.travel(path, title: title, replace: replace);
    if (trip == null) {
      return null;
    }

    var history = js.context['history'] as js.JsObject;
    history.callMethod(
      replace ? 'replaceState' : 'pushState',
      <dynamic>[
        '',
        title,
        path,
      ],
    );
    // Actually call the callback.
    trip.route.travel(trip);

    return trip;
  }

  @override
  void go(int steps) {
    js.context.callMethod(
      'history.go',
      <dynamic>[
        steps,
      ],
    );
  }
}

Nomad makeNomad() => NomadWeb();
