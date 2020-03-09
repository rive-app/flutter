import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/rive/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

void main() {
  test('Theme data is available from RiveThemeData', () {
    final theme = RiveThemeData();
    expect(theme.colors.accentBlue, const Color(0xFF57A5E0));
  });

  testWidgets('RiveTheme inherited widget is accessible down the tree',
      (tester) async {
    final myWidgetTree = RiveTheme(
      child: Builder(
        builder: (context) {
          return Container(
            color: RiveTheme.of(context).colors.accentMagenta,
          );
        },
      ),
    );

    await tester.pumpWidget(myWidgetTree);
    final containerFinder =
        byContainerColor(RiveThemeData().colors.accentMagenta);
    expect(containerFinder, findsOneWidget);
  });
}

/// Here's an example of a custom finder.
/// Bit of overkill here, but useful as an example.
Finder byContainerColor(Color color, {bool skipOffstage = true}) =>
    _ContainerColorFinder(color, skipOffstage: skipOffstage);

class _ContainerColorFinder extends MatchFinder {
  _ContainerColorFinder(this.color, {bool skipOffstage = true})
      : super(skipOffstage: skipOffstage);

  final Color color;

  @override
  String get description => 'color: $color';

  @override
  bool matches(Element candidate) {
    final Widget widget = candidate.widget;

    if (widget is Container) {
      return widget.color == color;
    }

    return false;
  }
}
