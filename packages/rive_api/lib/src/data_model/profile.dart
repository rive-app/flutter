import 'package:utilities/deserialize.dart';

class ProfileDM {
  const ProfileDM({
    this.name,
    this.username,
    this.email,
    this.avatar,
    this.website,
    this.bio,
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

  final String name;
  final String username;
  final String email;
  final String avatar;
  final String website;
  final String bio;
  final String location;
  final String twitter;
  final String instagram;
  final String dribbble;
  final String linkedin;
  final String behance;
  final String vimeo;
  final String github;
  final String medium;
  final bool isForHire;

  factory ProfileDM.fromData(Map<String, dynamic> data) => ProfileDM(
        name: data.getString('name'),
        username: data.getString('username'),
        email: data.getString('email'),
        website: data.getString('website'),
        bio: data.getString('bio'),
        location: data.getString('location'),
        twitter: data.getString('twitter'),
        instagram: data.getString('instagram'),
        linkedin: data.getString('linkedin'),
        medium: data.getString('medium'),
        github: data.getString('github'),
        behance: data.getString('behance'),
        vimeo: data.getString('vimeo'),
        dribbble: data.getString('dribbble'),
        isForHire: data.getBool('isForHire'),
      );

  @override
  String toString() => "name: $name\n"
      "username: $username\n"
      "email: $email\n"
      "location: $location\n"
      "avatar: $avatar\n"
      "website: $website\n"
      "bio: $bio\n"
      "twitter: $twitter\n"
      "instagram: $instagram\n"
      "dribbble: $dribbble\n"
      "linkedin: $linkedin\n"
      "behance: $behance\n"
      "vimeo: $vimeo\n"
      "github: $github\n"
      "medium: $medium\n"
      "isForHire: $isForHire";
}
