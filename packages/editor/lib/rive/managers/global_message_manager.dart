import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';

class GlobalMessageManager with Subscriptions {
  static final GlobalMessageManager _instance = GlobalMessageManager._();
  factory GlobalMessageManager() => _instance;

  GlobalMessageManager._() {
    _plumber = Plumber();
    _attach();
  }

  void _attach() {
    subscribe<HomeSection>(_clearGlobalMessage);
    subscribe<CurrentDirectory>(_clearGlobalMessage);
    subscribe<RiveTabItem>(_clearGlobalMessage);
  }

  void _clearGlobalMessage(dynamic _) {
    _plumber.flush<GlobalMessage>();
  }

  Plumber _plumber;
}
