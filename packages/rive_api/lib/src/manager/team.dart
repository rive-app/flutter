import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/view_model/team.dart';

class TeamListManager {
  static void getTeams(int ownerId) {
    // api.getTeams(ownerId)
    final riveTeam = Team(2, 'Rive', 'rive_logo.png');
    final spotifyTeam = Team(3, 'Spotify', 'spotify_logo.png');

    Plumber().message(
      TeamList(
        [
          riveTeam,
          spotifyTeam,
        ],
      ),
    );
  }
}
