import 'package:rive_api/src/deserialize_helper.dart';

class RiveTeam {
  final int id;
  final int ownerId;
  final String name;

  RiveTeam({this.id, this.ownerId, this.name});

  @override
  String toString() {
    return 'RiveTeam($ownerId, @$name)';
  }

  factory RiveTeam.fromData(Map<String, dynamic> data) {
    return RiveTeam(
        id: data.getInt('id'),
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'));
  }
}
