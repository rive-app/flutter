import 'package:rive_api/data_model.dart';

abstract class Owner {
  const Owner(
    this.ownerId,
    this.name,
    this.username,
    this.avatarUrl,
  );
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  OwnerDM get asDM;

  String get displayName => name ?? username;
}
