export 'src/model/current_directory.dart';
export 'src/model/file.dart';
export 'src/model/folder.dart';
export 'src/model/folder_contents.dart';
export 'src/model/folder_tree.dart';
export 'src/model/me.dart';
export 'src/model/notification.dart';
export 'src/model/owner.dart';
export 'src/model/team.dart';
export 'src/model/user.dart';


/// Szudzik's function for hashing two ints together: in this case
/// <ownerId, folderId>
int szudzik(int a, int b) {
  // a and b must be >= 0
  assert(a >= 0);
  assert(b >= 0);
  int x = a.abs();
  int y = b.abs();
  return x >= y ? x * x + x + y : x + y * y;
}
