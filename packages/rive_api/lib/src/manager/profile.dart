import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class ProfileManager {
  static ProfileManager _instance = ProfileManager._();

  factory ProfileManager() => _instance;

  ProfileManager._() : _meApi = MeApi(), _teamApi = TeamApi();

  ProfileManager.tester(MeApi meApi, TeamApi teamApi) {
    _meApi = meApi;
    _teamApi = teamApi;
  }

  MeApi _meApi;
  TeamApi _teamApi;
  Plumber get _plumber => Plumber();

  // used for testing atm.
  void set meApi(MeApi meApi) => _meApi = meApi;

  // used for testing atm.
  void set teamApi(TeamApi teamApi) => _teamApi = teamApi;

  void loadProfile(Owner owner) async {
    final ownerId = owner.ownerId;
    if (owner is Team) {
      // Load team profile.
      final teamProfile = Profile.fromDM(await _teamApi.getProfile(ownerId));
      _plumber.message<Profile>(teamProfile, ownerId);
    } else {
      // Load user profile
      final userProfile = Profile.fromDM(await _meApi.profile);
      _plumber.message<Profile>(userProfile, ownerId);
    }
  }
  
  Future<void> updateProfile(Owner owner, Profile profile) async {
    if (owner is Team) {
      await _teamApi.updateProfile(owner, profile);
    } else {
      await _meApi.updateProfile(profile);
    }
    _plumber.message<Profile>(profile, owner.ownerId);
  }
}