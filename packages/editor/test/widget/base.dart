import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/images/icon_atlases')) {
      return ByteData.view(
          (await File('assets/rive.png').readAsBytes()).buffer);
    }
    return null;
  }
}

Widget bootstrapped(Widget child) {
  return RiveTheme(
      child: IconCache(
          cache: RiveIconCache(TestAssetBundle()),
          child:
              Directionality(textDirection: TextDirection.ltr, child: child)));
}
