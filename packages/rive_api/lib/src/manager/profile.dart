import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._();

  factory ProfileManager() => _instance;

  ProfileManager._()
      : meApi = MeApi(),
        teamApi = TeamApi();

  ProfileManager.tester(this.meApi, this.teamApi);

  MeApi meApi;
  TeamApi teamApi;
  Plumber get _plumber => Plumber();

  Future<void> loadProfile(Owner owner) async {
    final ownerId = owner.ownerId;
    Profile profile;
    if (owner is Team) {
      // Load team profile.
      profile = Profile.fromDM(await teamApi.getProfile(ownerId));
    } else {
      // Load user profile
      profile = Profile.fromDM(await meApi.profile);
    }
    _plumber.message<Profile>(profile, ownerId);
  }

  Future<bool> updateProfile(Owner owner, Profile profile) async {
    bool success;
    if (owner is Team) {
      success = await teamApi.updateProfile(owner, profile);
    } else {
      success = await meApi.updateProfile(profile);
    }
    if (success) {
      _plumber.message<Profile>(profile, owner.ownerId);
    }
    return success;
  }
}
