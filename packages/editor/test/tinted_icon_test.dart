import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/images/icons')) {
      return ByteData.view(
          (await File('assets/rive.png').readAsBytes()).buffer);
    }
    return null;
  }
}

class TestPathAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key == 'assets/images/icons/test-image.png') {
      return ByteData.view(
          (await File('assets/rive.png').readAsBytes()).buffer);
    }
    return null;
  }
}

void main() {
  group('Tinted Icons', () {
    testWidgets('Tinted Icon renders', (tester) async {
      await tester.pumpWidget(
        IconCache(
          cache: RiveIconCache(TestAssetBundle()),
          child: const TintedIcon(
            icon: 'dont-care',
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      expect(find.byType(TintedIcon), findsOneWidget);
    });

    testWidgets('Icon data is found in the asset bundle', (tester) async {
      await tester.pumpWidget(
        IconCache(
          cache: RiveIconCache(TestPathAssetBundle()),
          child: const TintedIcon(
            icon: 'test-image',
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      expect(find.byType(TintedIcon), findsOneWidget);
    });
  });
}
