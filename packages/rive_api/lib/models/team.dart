import 'package:meta/meta.dart';

import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/src/deserialize_helper.dart';

/// Permissions users can have on a team
enum TeamPermission { read, write, purchase, admin, own }

extension TeamPermissionExtension on TeamPermission {
  String get name {
    switch (this) {
      case TeamPermission.read:
        return 'read';
      case TeamPermission.write:
        return 'write';
      case TeamPermission.purchase:
        return 'purchase';
      case TeamPermission.admin:
        return 'admin';
      case TeamPermission.own:
        return 'own';
      default:
        return null;
    }
  }
}

class RiveTeam extends RiveOwner {
  final int id;
  final List<RiveUser> _members = [];

  RiveTeam(
      {@required this.id,
      @required int ownerId,
      @required String name,
      @required username,
      String avatar})
      : super(id: ownerId, name: name, username: username, avatar: avatar);

  factory RiveTeam.fromData(Map<String, dynamic> data) => RiveTeam(
      id: data.getInt('id'),
      ownerId: data.getInt('ownerId'),
      name: data.getString('name'),
      username: data.getString('username'),
      avatar: data.getString('avatar'));

  /// Returns a list of teams from a JSON document
  static List<RiveTeam> fromDataList(List<dynamic> dataList) => dataList
      .map<RiveTeam>(
        (data) => RiveTeam.fromData(data),
      )
      .toList(growable: false);

  @override
  String get displayName => name;

  List<RiveUser> get teamMembers => _members;
  void set teamMembers(List<RiveUser> members) {
    _members
      ..clear()
      ..addAll(members);
  }

  int get size => _members.length;

  @override
  String toString() => 'RiveTeam($ownerId, @$name)';
}
