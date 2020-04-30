/// Manages all data inputs and outputs for Rive data

import 'package:rive_api/src/view_model/view_model.dart';
import 'package:rxdart/rxdart.dart';

/// API definition, contract for those interfacing
/// with the bus
abstract class BusApi {
  /// Basic user data: MeVM
  Stream<MeVM> get meStream;
  Sink<MeVM> get meSink;
}

/// Lower level access to controllers in the bus.
/// Sometimes needed by managers requiring controller
/// level access for configuringb themselves; e.g.
/// MeManager gets data when the controller is first
/// subscribed to.
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

  /// Basic user information: MeVM
  /// By using one controller for both the stream
  /// and sink, no further wiring required
  final _meController = BehaviorSubject<MeVM>();
  BehaviorSubject<MeVM> get meController => _meController;
  Stream<MeVM> get meStream => _meController.stream;
  Sink<MeVM> get meSink => _meController.sink;
}
