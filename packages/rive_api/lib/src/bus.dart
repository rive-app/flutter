/// Manages all data inputs and outputs for Rive data

import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rxdart/rxdart.dart';

/// API definition
abstract class BusApi {
  /// Basic user data: name and avatar
  Stream<MeVM> get meStream;
  Sink<MeVM> get meSink;
}

abstract class BusConfiguration {
  /// Basic user data configuration
  BehaviorSubject<MeVM> get meController;
}

/// API implementation
class Bus implements BusApi, BusConfiguration {
  /// Bus is a singleston
  Bus._();
  static Bus _instance = Bus._();
  factory Bus() => _instance;

  /// Basic user information: name and avatar
  /// By using one controller for both the stream
  /// and sink, no further wiring required
  final _meController = BehaviorSubject<MeVM>();
  BehaviorSubject<MeVM> get meController => _meController;
  Stream<MeVM> get meStream => _meController.stream;
  Sink<MeVM> get meSink => _meController.sink;
}
