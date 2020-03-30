import 'package:core/coop/player.dart';
import 'package:flutter/foundation.dart';
import 'package:rive_api/models/user.dart';

abstract class ClientSidePlayerDelegate {
  void cursorChanged();
  void userChanged(RiveUser user, int index);
}

class ClientSidePlayer extends Player {
  final bool isSelf;

  RiveUser get user => userNotifier.value;
  set user(RiveUser value) {
    userNotifier.value = value;
    cursorDelegate?.userChanged(value, _index);
  }

  int _index = 0;
  int get index => _index;
  set index(int value) {
    if (_index == value) {
      return;
    }
    _index = value;
    if (userNotifier.value != null) {
      cursorDelegate?.userChanged(userNotifier.value, value);
    }
  }

  final ValueNotifier<RiveUser> userNotifier = ValueNotifier<RiveUser>(null);
  ClientSidePlayer(Player serverPlayer, this.isSelf)
      : super(serverPlayer.clientId, serverPlayer.ownerId);

  ClientSidePlayerDelegate _cursorDelegate;
  ClientSidePlayerDelegate get cursorDelegate => _cursorDelegate;
  set cursorDelegate(ClientSidePlayerDelegate value) {
    _cursorDelegate = value;
    // Let the delegate know what the user is, if we have one.
    if (userNotifier.value != null) {
      _cursorDelegate?.userChanged(userNotifier.value, _index);
    }
  }

  @override
  void cursorChanged() {
    cursorDelegate?.cursorChanged();
  }
}
