import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';

class ProfileManager {
  static final ProfileManager _instance = ProfileManager._();

  factory ProfileManager() => _instance;

  ProfileManager._() : meApi = MeApi(), teamApi = TeamApi();

  ProfileManager.tester(MeApi meApi, TeamApi teamApi) {
    meApi = meApi;
    teamApi = teamApi;
  }

  MeApi meApi;
  TeamApi teamApi;
  Plumber get _plumber => Plumber();

  Future<void> loadProfile(Owner owner) async {
    final ownerId = owner.ownerId;
    if (owner is Team) {
      // Load team profile.
      final teamProfile = Profile.fromDM(await teamApi.getProfile(ownerId));
      _plumber.message<Profile>(teamProfile, ownerId);
    } else {
      // Load user profile
      final userProfile = Profile.fromDM(await meApi.profile);
      _plumber.message<Profile>(userProfile, ownerId);
    }
  }
  
  Future<void> updateProfile(Owner owner, Profile profile) async {
    if (owner is Team) {
      await teamApi.updateProfile(owner, profile);
    } else {
      await meApi.updateProfile(profile);
    }
    _plumber.message<Profile>(profile, owner.ownerId);
  }
}