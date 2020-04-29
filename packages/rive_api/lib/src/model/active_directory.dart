import 'package:rive_api/src/model/model.dart';
import 'package:meta/meta.dart';

/// Model for an open directory
class ActiveDirectory {
  ActiveDirectory(
      {@required int id,
      this.name,
      this.directories = const [],
      this.files = const []})
      : _id = id;
  final int _id;
  final String name;
  final List<Directory> directories;
  final List<File> files;
}

class File {
  File({@required int id, @required this.name}) : _id = id;
  final int _id;
  final String name;
}
