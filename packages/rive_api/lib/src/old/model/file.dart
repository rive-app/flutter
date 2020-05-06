// import 'package:utilities/deserialize.dart';
// import 'package:meta/meta.dart';

// class File {
//   File({
//     @required this.id,
//     this.name,
//     this.ownerId,
//     this.preview,
//   });
//   final int id;
//   final int ownerId;
//   final String name;
//   final String preview;

//   static Iterable<File> fromDataList(List<dynamic> data) =>
//       data.map((d) => File.fromData(d));

//   factory File.fromData(Map<String, dynamic> data) => File(
//         ownerId: data.getInt('oid'),
//         name: data.getString('name'),
//         preview: data.getString('preview'),
//         id: data.getInt('id'),
//       );

//   static Iterable<File> fromIdList(List<int> data, int ownerId) =>
//       data.map((id) => File(id: id, ownerId: ownerId));
// }
