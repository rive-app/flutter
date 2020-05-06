import 'package:meta/meta.dart';

abstract class OwnerDM {
  const OwnerDM({
    @required this.ownerId,
    @required this.name,
    @required this.username,
  });
  final int ownerId;
  final String name;
  final String username;
}
