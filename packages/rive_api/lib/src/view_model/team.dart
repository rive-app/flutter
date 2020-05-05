import 'package:rive_api/src/view_model/view_model.dart';

class TeamVM extends ViewModel {
  const TeamVM(this.id, this.name, this.avatarUrl);
  
  final int id;
  final String name;
  final String avatarUrl;

  @override
  String get description => "ID: $id, $name";
}

class TeamList extends ViewModel {
  const TeamList(this.teams);
  final List<TeamVM> teams;

  @override
  String get description => "My Teams: $teams";
}