import 'package:meta/meta.dart';

abstract class Owner {
  const Owner({
    @required this.ownerId,
    @required this.name,
    @required this.username,
  });
  final int ownerId;
  final String name;
  final String username;
}
