import 'dart:convert';

import 'package:rive_api/data_model.dart';

class Profile {
  const Profile({
    this.name,
    this.username,
    this.password,
    this.email,
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
  final String password;
  final String email;
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

  factory Profile.fromDM(ProfileDM profile) => Profile(
        name: profile?.name,
        username: profile?.username,
        email: profile?.email,
        website: profile?.website,
        bio: profile?.bio,
        location: profile?.location,
        twitter: profile?.twitter,
        instagram: profile?.instagram,
        linkedin: profile?.linkedin,
        medium: profile?.medium,
        github: profile?.github,
        behance: profile?.behance,
        vimeo: profile?.vimeo,
        dribbble: profile?.dribbble,
        isForHire: profile?.isForHire,
      );

  ProfileDM get asDM => ProfileDM(
        name: name,
        username: username,
        email: email,
        website: website,
        bio: bio,
        location: location,
        twitter: twitter,
        instagram: instagram,
        dribbble: dribbble,
        linkedin: linkedin,
        behance: behance,
        vimeo: vimeo,
        github: github,
        medium: medium,
        isForHire: isForHire,
      );

  String get encoded => jsonEncode({
        'name': name,
        'username': username,
        'email': email,
        'location': location,
        'website': website,
        'blurb': bio,
        'twitter': twitter,
        'instagram': instagram,
        'dribbble': dribbble,
        'linkedin': linkedin,
        'behance': behance,
        'vimeo': vimeo,
        'github': github,
        'medium': medium,
        'isForHire': isForHire,
        'password': password,
      });

  @override
  String toString() => 'name: $name\n'
      'username: $username\n'
      'email: $email\n'
      'location: $location\n'
      'website: $website\n'
      'bio: $bio\n'
      'twitter: $twitter\n'
      'instagram: $instagram\n'
      'dribbble: $dribbble\n'
      'linkedin: $linkedin\n'
      'behance: $behance\n'
      'vimeo: $vimeo\n'
      'github: $github\n'
      'medium: $medium\n'
      'isForHire: $isForHire';
}
