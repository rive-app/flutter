import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rive_api/user.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'user.dart';

const ASCII_START = 33;
const ASCII_END = 126;

class ConntectedUsersContext {
  final currentFile = ValueNotifier<RiveTabItem>(null);
  final users = ValueNotifier<List<ConnectedUser>>([]);
  final random = Random();
  Timer _timer;
  void init() {
    _timer?.cancel();
    users.value = [];
    _addFakeUser(1);
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _addFakeUser(random.nextInt(2));
      _removeFakeUser(random.nextInt(2));
    });
  }

  void _removeFakeUser(int amount) {
    // print('Removing Users: $amount');
    for (var i = 0; i < amount; i++) {
      if (users.value.length == 1) return;
      final _list = List<ConnectedUser>.from(users.value);
      _list.removeLast();
      users.value = _list;
    }
    users.notifyListeners();
  }

  void _addFakeUser(int amount) {
    // print('Adding Users: $amount');
    for (var i = 0; i < amount; i++) {
      if (users.value.length > 10) return;
      final _list = List<ConnectedUser>.from(users.value);
      _list.add(ConnectedUser(
        user: RiveUser(
          name: String.fromCharCodes(List.generate(20, (index) {
            return randomBetween(ASCII_START, ASCII_END);
          })),
          avatar: 'https://i.pravatar.cc/?img=$i',
        ),
        colorValue: _getRandomColor(),
      ));
      users.value = _list;
    }
    users.notifyListeners();
  }

  int _getRandomColor() {
    final _lerp = random.nextDouble();
    final _color = Color.lerp(Colors.red, Colors.blue, _lerp);
    return _color.value;
  }
}

/// Generates a random integer where [from] <= [to].
int randomBetween(int from, int to) {
  final random = Random();
  if (from > to) throw Exception('$from cannot be > $to');
  double randomDouble = random.nextDouble();
  if (randomDouble < 0) randomDouble *= -1;
  if (randomDouble > 1) randomDouble = 1 / randomDouble;
  return ((to - from) * random.nextDouble()).toInt() + from;
}
