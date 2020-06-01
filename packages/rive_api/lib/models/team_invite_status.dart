import 'package:utilities/deserialize.dart';

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
