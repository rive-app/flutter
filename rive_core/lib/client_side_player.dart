import 'package:core/coop/player.dart';
import 'package:flutter/foundation.dart';
import 'package:rive_api/user.dart';

class ClientSidePlayer extends Player {
  final ValueNotifier<RiveUser> user = ValueNotifier<RiveUser>(null);
  ClientSidePlayer(Player serverPlayer)
      : super(serverPlayer.clientId, serverPlayer.ownerId);
}
