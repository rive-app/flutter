import 'package:meta/meta.dart';

import 'package:rive_api/owner.dart';
import 'package:rive_api/src/deserialize_helper.dart';

class RiveTeam extends RiveOwner {
  final int id;

  const RiveTeam(
      {@required this.id, @required int ownerId, @required String name})
      : super(id: ownerId, name: name);

  factory RiveTeam.fromData(Map<String, dynamic> data) => RiveTeam(
      id: data.getInt('id'),
      ownerId: data.getInt('ownerId'),
      name: data.getString('name'));

  /// Returns a list of teams from a JSON document
  static List<RiveTeam> fromDataList(List<dynamic> dataList) => dataList
      .map<RiveTeam>(
        (data) => RiveTeam.fromData(data),
      )
      .toList(growable: false);

  @override
  String toString() => 'RiveTeam($ownerId, @$name)';
}
