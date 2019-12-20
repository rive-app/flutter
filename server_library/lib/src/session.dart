/// Repesents a unique client session. Sessions are longer lived than
/// connections and can be resumed. Users can have multiple sessions.
class Session {
  /// Unique session id.
  int id;

  /// Last received change id.
  int changeId;

  /// User id from the database.
  String userId;
}