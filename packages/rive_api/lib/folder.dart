import 'src/deserialize_helper.dart';

class RiveApiFolder {
  final String _parentId;
  final String id;
  final String name;
  final int order;
  RiveApiFolder _parent;
  RiveApiFolder get parent => _parent;
  String get parentId => _parentId;

  final List<RiveApiFolder> children = [];

  RiveApiFolder(Map<String, dynamic> data)
      : id = data.getString('id'),
        _parentId = data.getString('parent'),
        name = data.getString('name'),
        order = data.getInt('order');

  RiveApiFolder.fromName(this.name)
      : id = null,
        _parentId = null,
        order = -1;

  bool findParent(List<RiveApiFolder> folders, [RiveApiFolder all]) {
    if (_parentId == null && all != this) {
      _parent = all;
      _parent?.children?.add(this);
    } else {
      _parent = folders.firstWhere((item) => item.id == _parentId,
          orElse: () => null);
      _parent?.children?.add(this);
    }
    return _parent != null;
  }

  @override
  String toString() {
    return 'Folder($_parentId:$id, $name)';
  }
}
