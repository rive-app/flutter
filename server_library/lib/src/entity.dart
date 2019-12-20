/// An item in the file that has a pre-known (on client) key to resolve it.
/// Entities are stored with the session id that owns it and the server change
/// id associated with creation/change.
class Entity {
  /// Represents the kind of entity this is.
  int key;

  /// The client's session id.
  int sessionId;

  /// The serverside change id that created or changed this entity.
  int serverChangeId;
}
