import 'src/deserialize_helper.dart';

class RiveFolder {
  final String _parentId;
  final String id;
  final String name;
  final int order;
  RiveFolder _parent;
  RiveFolder get parent => _parent;

  final List<RiveFolder> children = [];

  RiveFolder(Map<String, dynamic> data)
      : id = data.getString('id'),
        _parentId = data.getString('parent'),
        name = data.getString('name'),
        order = data.getInt('order');

  RiveFolder.fromName(this.name)
      : id = null,
        _parentId = null,
        order = -1;

  bool findParent(List<RiveFolder> folders) {
    _parent =
        folders.firstWhere((item) => item.id == _parentId, orElse: () => null);
    _parent?.children?.add(this);
    return _parent != null;
  }

  @override
  String toString() {
    return 'Folder($_parentId:$id, $name)';
  }
}
