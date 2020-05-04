import 'package:rive_api/src/view_model/view_model.dart';

class CurrentDirectory extends ViewModel {
  const CurrentDirectory(this.id, this.name);
  final int id;
  final String name;

  @override
  String get description => "Current Directory: $name, ID: $id";
}
