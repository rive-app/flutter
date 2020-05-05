/// Tree of directories
import 'package:meta/meta.dart';
import 'package:quiver/core.dart';
import 'package:utilities/deserialize.dart';

class Folder {
  Folder({
    @required this.id,
    @required this.ownerId,
    @required this.name,
    @required this.parent,
    @required this.order,
  });
  final int id;
  final int ownerId;
  final int parent;
  final int order;
  final String name;

  static Iterable<Folder> fromDataList(List<dynamic> data) =>
      data.map((d) => Folder.fromData(d));

  factory Folder.fromData(
    Map<String, dynamic> data,
  ) =>
      Folder(
        id: data.getInt('id'),
        ownerId: data.containsKey('project_owner_id')
            ? data.getInt('project_owner_id')
            : null,
        name: data.getString('name'),
        order: data.getInt('order'),
        parent: data.getInt('parent'),
      );

  @override
  String toString() => 'Folder($name)';

  @override
  bool operator ==(o) => o is Folder && o.id == id && o.ownerId == ownerId;

  @override
  int get hashCode => hash2(id, ownerId);
}
