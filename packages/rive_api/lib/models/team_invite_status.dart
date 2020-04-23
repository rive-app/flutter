enum TeamInviteStatus { accepted, pending }

extension DeserializeHelper on Map<String, dynamic> {
  TeamInviteStatus getInvitationStatus() {
    dynamic value = this['status'];
    switch (value) {
      case 'pending':
        return TeamInviteStatus.pending;
      case 'complete':
        return TeamInviteStatus.accepted;
      default:
        return TeamInviteStatus.pending;
    }
  }
}
