/// Manager for a user's followers and followees

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:rive_api/api.dart';

import 'package:rive_api/apis/follow.dart';
import 'package:rive_api/models/follow.dart';
import 'package:rxdart/rxdart.dart';

/// Followers not wired up yet, just followees
class FollowManager {
  FollowManager({
    @required RiveApi api,
    @required this.ownerId,
  }) : _api = FollowingApi(api) {
    _init();
  }
  final FollowingApi _api;
  final int ownerId;

  /*
   * State
   */

  /// Set of those that the user is following
  final _followees = <RiveFollowee>{};

  /*
   * Streams
   */

  /// Outbound stream of an iterable of those following the user
  // final _followersController = BehaviorSubject<Iterable<int>>();
  // Stream<Iterable<int>> get followersStream => _followersController.stream;

  /// Outbound stream of an iterable of those that the user is following
  final _followeesController = BehaviorSubject<Iterable<RiveFollowee>>();
  Stream<Iterable<RiveFollowee>> get followeesStream =>
      _followeesController.stream;

  /*
   * Sinks
   */

  /// Inbound sink to follow a user
  final _followController = StreamController<int>.broadcast();
  Sink<int> get followSink => _followController;

  /// Inbound sink to unfollow a user
  final _unfollowController = StreamController<int>.broadcast();
  Sink<int> get unfollowSink => _unfollowController;

  void dispose() {
    _followeesController.close();
    _followController.close();
    _unfollowController.close();
  }

  void _init() {
    // Fetch the list of followees
    _fetchFollowees();
    // Handle sink to follow a user
    _followController.stream.listen(_follow);

    // Handle sink to unfollow a user
    _unfollowController.stream.listen(_unfollow);
  }

  Future<void> _fetchFollowees() async {
    _followees.clear();
    _followees.addAll(await _api.followees(ownerId));
    _followeesController.add(_followees);
  }

  Future<void> _follow(int ownerId) async {
    await _api.follow(ownerId);
    await _fetchFollowees();
  }

  Future<void> _unfollow(int ownerId) async {
    await _api.unfollow(ownerId);
    _followees.removeWhere((e) => e.ownerId == ownerId);
    _followeesController.add(_followees);
  }
}
