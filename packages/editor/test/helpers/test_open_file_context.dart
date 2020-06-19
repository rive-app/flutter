import 'package:rive_core/rive_file.dart';
import 'package:local_data/local_data.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';

/// A fake open file context that's valid and usable for testing.
class TestOpenFileContext extends OpenFileContext {
  TestOpenFileContext() : super(10, 10, rive: Rive());
  Future<bool> fakeConnect() async {
    LocalDataPlatform dataPlatform = LocalDataPlatform.make();
    core = TestRiveFile('fake', localDataPlatform: dataPlatform);
    core.onConnected();
    completeInitialConnection(OpenFileState.open);
    return true;
  }
}

class TestRiveFile extends RiveFile {
  final Map<String, dynamic> overridePreferences;
  final bool useSharedPreferences;

  TestRiveFile(
    String fileId, {
    LocalDataPlatform localDataPlatform,
    this.overridePreferences,
    this.useSharedPreferences = true,
  }) : super(
          fileId,
          localDataPlatform: localDataPlatform,
        );

  @override
  Future<int> getIntSetting(String key) async {
    if (overridePreferences != null) {
      dynamic val = overridePreferences[key];
      if (val is int) {
        return val;
      }
    }
    if (!useSharedPreferences) {
      return null;
    }
    return super.getIntSetting(key);
  }

  @override
  Future<String> getStringSetting(String key) async {
    if (overridePreferences != null) {
      dynamic val = overridePreferences[key];
      if (val is String) {
        return val;
      }
    }
    if (!useSharedPreferences) {
      return null;
    }
    return super.getStringSetting(key);
  }

  @override
  Future<void> setIntSetting(String key, int value) async {
    if (!useSharedPreferences) {
      return;
    }
    return super.setIntSetting(key, value);
  }

  @override
  Future<void> setStringSetting(String key, String value) async {
    if (!useSharedPreferences) {
      return;
    }
    return super.setStringSetting(key, value);
  }
}
