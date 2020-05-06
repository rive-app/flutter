// /// Manages all data inputs and outputs for Rive data

// import 'dart:async';

// import 'package:rive_api/src/view_model/view_model.dart';
// import 'package:rxdart/rxdart.dart';

// /// API definition, contract for those interfacing
// /// with the bus. This is what's available to the
// /// UI.
// abstract class BusApi {
//   /// User data: MeVM
//   Stream<MeVM> get meStream;

//   /// Volume data: MeVolume
//   Stream<Iterable<VolumeVM>> get volumeStream;
// }

// /// Lower level access to controllers in the bus.
// /// Sometimes needed by managers requiring controller
// /// level access for configuring themselves; e.g.
// /// MeManager gets data when the controller is first
// /// subscribed to. These are only available to managers
// /// at initialization.
// abstract class BusConfiguration {
//   /// User stream configuration
//   StreamController<MeVM> get meController;

//   /// Volume stream configuration
//   StreamController<Iterable<VolumeVM>> get volumeController;

//   /// Active directory stream configuration
//   /// Note that we dont need to expose the stream if only
//   /// the managers are using it, as it will get plumbed directly
//   /// into them.
//   StreamController<DirectoryVM> get activeDirController;
// }

// /// API implementation
// class Bus implements BusApi, BusConfiguration {
//   /// Bus is a singleston
//   Bus._();
//   static Bus _instance = Bus._();
//   factory Bus() => _instance;

//   /// User datta: MeVM
//   /// By using one controller for both the stream
//   /// and sink, no further wiring required
//   final _meController = BehaviorSubject<MeVM>();
//   BehaviorSubject<MeVM> get meController => _meController;
//   Stream<MeVM> get meStream => _meController.stream;

//   /// Volume data: VolumeVM
//   final _volumeController = BehaviorSubject<Iterable<VolumeVM>>();
//   BehaviorSubject<Iterable<VolumeVM>> get volumeController => _volumeController;
//   Stream<Iterable<VolumeVM>> get volumeStream => _volumeController.stream;

//   /// Active directory
//   final _activeDirController = BehaviorSubject<DirectoryVM>();
//   BehaviorSubject<DirectoryVM> get activeDirController => _activeDirController;
//   Stream<DirectoryVM> get activeDirStream => _activeDirController.stream;
// }
