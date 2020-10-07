import 'dart:collection';
import 'package:meta/meta.dart';

import 'src/nomad_native.dart' if (dart.library.html) 'src/nomad_web.dart';

enum WaypointType {
  landmark,
  parameter,
  optionalParameter,
  arrayParameter,
}

/// The segment in path of a route (segment0/segment1/segment2).
class Waypoint {
  final String segment;
  final WaypointType type;
  final int matchGroup;

  const Waypoint({
    this.segment,
    this.type,
    this.matchGroup = 0,
  });

  @override
  String toString() {
    switch (type) {
      case WaypointType.landmark:
        return segment;
        break;
      case WaypointType.parameter:
        return ':$segment';
        break;
      case WaypointType.optionalParameter:
        return ':$segment?';
        break;
      case WaypointType.arrayParameter:
        return ':$segment*';
        break;
    }
    return super.toString();
  }
}

/// The well defined navigatable path.
class Route {
  final List<Waypoint> waypoints;
  final RegExp regex;
  final void Function(Trip) travel;
  Route(this.waypoints, this.regex, this.travel);

  @override
  String toString() {
    return 'Route: $waypoints';
  }

  factory Route.fromPath(String path, void Function(Trip) travel) {
    String expression = '';
    var points = <Waypoint>[];
    int matchGroup = 0;

    path = path.replaceAll(RegExp('^\/+'), '');

    for (final segment in path.split('/')) {
      var parameterName = segment.substring(1).toLowerCase();
      if (segment[0] == ':') {
        WaypointType type;
        if (segment[segment.length - 1] == '?') {
          type = WaypointType.optionalParameter;
          parameterName = parameterName.substring(0, parameterName.length - 1);
          matchGroup += 1;
          if (expression.isNotEmpty) {
            matchGroup += 1;
            expression += '(\/|)';
          }
          expression += '([^\/]*?)';
        } else if (segment[segment.length - 1] == '*') {
          type = WaypointType.arrayParameter;
          parameterName = parameterName.substring(0, parameterName.length - 1);
          matchGroup += 1;
          if (expression.isNotEmpty) {
            matchGroup += 1;
            expression += '(\/|)';
          }
          expression += '(.*?)';
        } else {
          type = WaypointType.parameter;
          matchGroup += 1;

          if (expression.isNotEmpty) {
            expression += '\/';
          }
          expression += '([^\/]*?)';
        }
        points.add(Waypoint(
            segment: parameterName, matchGroup: matchGroup, type: type));
      } else {
        if (expression.isNotEmpty) {
          expression += '\/';
        }
        expression += segment.toLowerCase().replaceAll('*', '[^\/]*?');
        points.add(Waypoint(
            segment: segment.toLowerCase(), type: WaypointType.landmark));
      }
    }
    return Route(points, RegExp('^$expression\$'), travel);
  }

  /// Attempts taking this route, if the path validates.
  Trip attemptTravel(String path) {
    var cleanPath = path.replaceAll(RegExp('^(\/)+'), '');

    var match = regex.firstMatch(cleanPath);
    if (match == null) {
      return null;
    }

    HashMap<String, dynamic> parameters = HashMap<String, dynamic>();
    for (final waypoint in waypoints) {
      switch (waypoint.type) {
        case WaypointType.parameter:
          parameters[waypoint.segment] = match.group(waypoint.matchGroup);
          break;
        case WaypointType.optionalParameter:
          var value = match.group(waypoint.matchGroup);
          if (value.isEmpty) {
            value = null;
          }
          parameters[waypoint.segment] = value;
          break;
        case WaypointType.arrayParameter:
          var value = match.group(waypoint.matchGroup);
          parameters[waypoint.segment] =
              value.isEmpty ? null : value.split('/');
          break;
        default:
          break;
      }
    }
    return Trip(path, this, parameters, cleanPath.split('/'));
  }
}

/// An instance of a route with the values that were provided optional/parameter
/// driven segments.
class Trip {
  final String path;
  final Route route;
  final HashMap<String, dynamic> parameters;
  final List<String> segments;

  Trip(this.path, this.route, this.parameters, this.segments);
}

abstract class Nomad {
  final Set<Route> _registeredRoutes = {};
  Trip _location;
  Trip get location => _location;

  Nomad();

  /// Called to intiate a new trip to a route. Use [replace] = false to
  /// overwrite the current route in the navigation history.
  Trip travel(String path, {String title, bool replace = false}) {
    return _determineTrip(path);
  }

  Trip _determineTrip(String path) {
    for (final route in _registeredRoutes) {
      var trip = route.attemptTravel(path);
      if (trip != null) {
        return trip;
      }
    }
    return null;
  }

  @protected
  void internalTravel(Trip trip) {
    _location = trip;
    // Actually call the callback.
    trip.route.travel(trip);
  }

  /// Register a route, [travel] will be called when the app needs to display
  /// the contents for that route.
  Route route(String path, void Function(Trip) travel) {
    var route = Route.fromPath(path, travel);
    _registeredRoutes.add(route);
    return route;
  }

  /// Remove a route from the system.
  bool removeRoute(Route route) => _registeredRoutes.remove(route);

  /// Attempt going back.
  void back() => go(-1);

  /// Attempt going forward.
  void forward() => go(1);

  /// Travel in a specific direction by [steps].
  void go(int steps);

  bool makeFirstTrip();

  factory Nomad.make() => makeNomad();
}
