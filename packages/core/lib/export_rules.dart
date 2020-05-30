/// Implement this to help the exporter figure out how to place a Core object in
/// the exported filed.
class ExportRules {
  /// Returns true if the object wants to be included in the indexable list of
  /// artboard objects that are exported with the file. Including it in this
  /// list makes it easy to resolve at runtime via mapped Id->object index. Most
  /// objects that reference a parent (like keyframes) will export as a sublist
  /// of objects in the parent. However objects that need to be
  /// referenced/identified by multiple other objects are better suited to be
  /// exported in the artboard's object list and referenced by index at runtime.
  bool get exportAsContextObject => false;
}