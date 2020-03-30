import 'dart:convert';

import 'package:test/test.dart';

import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';

void main() {
  group('RiveTeam', () {
    test('Team objects are constructed correctly', () {
      final team = RiveTeam(id: 1, ownerId: 2, name: 'Team Awesome');

      expect(team.id, 1);
      expect(team.ownerId, 2);
      expect(team.name, 'Team Awesome');
    });

    test('Team objects are constructed from JSON correctly', () {
      final jsonData =
          jsonEncode({'id': 1, 'ownerId': 2, 'name': 'Team Awesome'});
      final team = RiveTeam.fromData(jsonDecode(jsonData));

      expect(team.id, 1);
      expect(team.ownerId, 2);
      expect(team.name, 'Team Awesome');
    });

    test('Team objects are constructed from a list of JSON objects correctly',
        () {
      final jsonData = jsonEncode([
        {'id': 1, 'ownerId': 2, 'name': 'Team Awesome'},
        {'id': 2, 'ownerId': 3, 'name': 'Team Deluxe'},
        {'id': 4, 'ownerId': 5, 'name': 'Team Supreme'}
      ]);
      final team = RiveTeam.fromDataList(jsonDecode(jsonData));

      expect(team.first.id, 1);
      expect(team.first.ownerId, 2);
      expect(team.first.name, 'Team Awesome');

      expect(team.last.id, 4);
      expect(team.last.ownerId, 5);
      expect(team.last.name, 'Team Supreme');
    });
  });

  group('RiveUser', () {
    test('User objects are constructed correctly', () {
      final user =
          RiveUser(ownerId: 1, name: 'User Awesome', username: 'user_awesome');

      expect(user.ownerId, 1);
      expect(user.name, 'User Awesome');
      expect(user.username, 'user_awesome');
      expect(user.avatar, null);
      expect(user.isAdmin, false);
      expect(user.isPaid, false);
      expect(user.notificationCount, 0);
      expect(user.isVerified, false);
    });
  });

  test('User objects are constructed from JSON correctly', () {
    final data = {
      'ownerId': 1,
      'name': 'User Awesome',
      'username': 'user_awesome',
      'isAdmin': true,
      'isPaid': true,
      'notificationCount': 1,
    };
    final jsonData = jsonEncode(data);

    var user = RiveUser.fromData(jsonDecode(jsonData), requireSignin: false);
    expect(user.ownerId, 1);
    expect(user.name, 'User Awesome');
    expect(user.username, 'user_awesome');
    expect(user.avatar, null);
    expect(user.isAdmin, true);
    expect(user.isPaid, true);
    expect(user.notificationCount, 1);
    expect(user.isVerified, false);

    user = RiveUser.fromData(jsonDecode(jsonData), requireSignin: true);
    expect(user, null);

    data['signedIn'] = true;
    user = RiveUser.fromData(data, requireSignin: true);
    expect(user.ownerId, 1);
  });
}
