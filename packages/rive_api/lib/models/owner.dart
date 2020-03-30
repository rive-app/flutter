/// The most basic elements of an owner of Rive assets/files
/// Subclassed by User and Team
abstract class RiveOwner {
  const RiveOwner({int id, this.name}) : _id = id;

  /// This id of the owner
  final int _id;

  /// The name of the owner
  final String name;

  /// Helper getter for subclasses of RiveOwner
  /// who might have multiple types of ids
  int get ownerId => _id;
}
