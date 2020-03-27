import 'package:rive_api/src/deserialize_helper.dart';

class RiveTeam {
  final int id;
  final int ownerId;
  final String name;

  RiveTeam({this.id, this.ownerId, this.name});

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
