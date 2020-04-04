import 'package:rive_api/src/deserialize_helper.dart';

class RiveProfile {
  final String website;
  final String bio;
  final String location;
  final String twitter;
  final String instagram;
  final bool isForHire;

  const RiveProfile({
    this.website,
    this.bio,
    this.location,
    this.twitter,
    this.instagram,
    this.isForHire,
  });

  factory RiveProfile.fromData(Map<String, dynamic> data) => RiveProfile(
      website: data.getString('website'),
      bio: data.getString('bio'),
      location: data.getString('location'),
      twitter: data.getString('twitter'),
      instagram: data.getString('instagram'),
      isForHire: data.getInt('isForHire') == 1);
}
