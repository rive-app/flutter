import 'coop_user.dart';

/// Repesents a unique client session. Sessions are longer lived than
/// connections and can be resumed. Users can have multiple sessions.
class CoopSession {
  /// Unique session id.
  int id;

  /// Last received change id.
  int changeId;

  /// User owning this session.
  CoopUser user;
}