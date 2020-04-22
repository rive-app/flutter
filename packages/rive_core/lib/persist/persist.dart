import 'package:core/coop/change.dart';
import 'package:local_data/local_data.dart';

import 'isolated_persist.dart' if (dart.library.html) 'web_persist.dart'
    as persist;

/// This will create the correct persister for the runtime platform
abstract class RivePersist {
  Future<List<ChangeSet>> changes();
  void wipe();
  void add(ChangeSet data);
  void remove(ChangeSet data);

  factory RivePersist(LocalDataPlatform localDataPlatform, String name) =>
      persist.IsolatedPersist(localDataPlatform, name);
}
