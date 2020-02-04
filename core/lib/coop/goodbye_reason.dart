enum GoodbyeReason {
  /// The client and server are not compatible, usually this means the user
  /// needs to upgrade their client.
  incompatible,

  /// A server internal error occurred, notify admins.
  serverError,

  /// Token didn't correspond to a signed in user.
  badToken,

  /// User doesn't have access to the requested file.
  noAccess,
}
