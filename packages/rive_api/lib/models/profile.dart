import 'package:utilities/deserialize.dart';

class RiveProfile {
  String name;
  String username;
  String email;
  String website;
  String blurb;
  String location;
  String twitter;
  String instagram;
  String dribbble;
  String linkedin;
  String behance;
  String vimeo;
  String github;
  String medium;
  bool isForHire;

  RiveProfile({
    this.name,
    this.username,
    this.email,
    this.website,
    this.blurb,
    this.location,
    this.twitter,
    this.instagram,
    this.dribbble,
    this.linkedin,
    this.behance,
    this.vimeo,
    this.github,
    this.medium,
    this.isForHire,
  });

  factory RiveProfile.fromData(Map<String, dynamic> data) => RiveProfile(
        name: data.getString('name'),
        username: data.getString('username'),
        email: data.getString('email'),
        website: data.getString('website'),
        blurb: data.getString('blurb'),
        location: data.getString('location'),
        twitter: data.getString('twitter'),
        instagram: data.getString('instagram'),
        dribbble: data.getString('dribbble'),
        linkedin: data.getString('linkedin'),
        behance: data.getString('behance'),
        vimeo: data.getString('vimeo'),
        github: data.getString('github'),
        medium: data.getString('medium'),
        isForHire: data.getInt('isForHire') == 1,
      );
}
