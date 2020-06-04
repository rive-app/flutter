import 'package:utilities/deserialize.dart';
import 'package:utilities/utilities.dart';

enum TeamInviteStatus { accepted, pending }

extension DeserializeHelper on Map<String, dynamic> {
  TeamInviteStatus getInvitationStatus() {
    switch (getString('status')) {
      case 'complete':
        return TeamInviteStatus.accepted;
      case 'pending':
      default:
        return TeamInviteStatus.pending;
    }
  }
}

extension TeamInviteStatusExtension on TeamInviteStatus {
  String get name => {
        TeamInviteStatus.accepted: 'complete',
        TeamInviteStatus.pending: 'pending',
      }[this];
}
