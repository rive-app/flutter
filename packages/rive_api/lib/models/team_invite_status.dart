enum TeamInviteStatus { accepted, pending }

extension DeserializeHelper on Map<String, dynamic> {
  TeamInviteStatus getInvitationStatus() {
    dynamic value = this['status'];
    switch (value) {
      case 'complete':
        return TeamInviteStatus.accepted;
      case 'pending':
      default:
        return TeamInviteStatus.pending;
    }
  }
}
