import 'package:flutter/foundation.dart';
import 'package:utilities/utilities.dart';

enum TeamRole { reader, member, purchaser, admin, owner }

final adminRoles = const {TeamRole.admin, TeamRole.owner};

extension DeserializeHelper on Map<String, dynamic> {
  TeamRole getTeamRole() =>
      TeamRoleExtension.teamRoleFromString(this['permission']);
}

bool canEditTeam(TeamRole role) => adminRoles.contains(role);

/// TeamRole helper functions and extensions
extension TeamRoleExtension on TeamRole {
  String get name => describeEnum(this).capsFirst;

  static List<String> get names =>
      TeamRole.values.map((e) => describeEnum(e).capsFirst).toList();

  static TeamRole teamRoleFromString(String value) {
    switch (value) {
      case 'Reader':
        return TeamRole.reader;
      case 'Member':
        return TeamRole.member;
      case 'Purchaser':
        return TeamRole.purchaser;
      case 'Admin':
        return TeamRole.admin;
      case 'Owner':
        return TeamRole.owner;
      default:
        return null;
    }
  }
}
