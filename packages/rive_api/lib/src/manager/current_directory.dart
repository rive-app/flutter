import 'package:rive_api/src/plumber.dart';
import 'package:rive_api/src/view_model/directory.dart';

class CurrentDirectoryManager {
  static setDirectory(int id) async {
    // Go fetch the directory from the api
    /// await directory with [id]
    CurrentDirectory dir;
    if (id == 0) {
      dir = CurrentDirectory(0, "Your Files");
    } else {
      // get other directories?
      throw UnsupportedError('Need to implement this too!');
    }
    Plumber().message(dir);
  }
}
