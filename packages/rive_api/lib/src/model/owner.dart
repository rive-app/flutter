import 'package:meta/meta.dart';
import 'package:rive_api/src/data_model/data_model.dart';

abstract class Owner {
  const Owner({
    @required this.ownerId,
    @required this.name,
    @required this.username,
  });
  final int ownerId;
  final String name;
  final String username;

  OwnerDM get asDM;
}
