import 'package:utilities/deserialize.dart';

class Volume {
  const Volume({this.name});
  final String name;

  factory Volume.fromData(Map<String, dynamic> data) =>
      Volume(name: data.getString('name'));

  /// Returns a list of volumes from a JSON document
  static Iterable<Volume> fromDataList(List<dynamic> dataList) =>
      dataList.map((data) => Volume.fromData(data));

  @override
  String toString() => 'Volume($name)';
}
