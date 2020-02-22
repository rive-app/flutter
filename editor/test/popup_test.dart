import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';
import 'package:rive_editor/widgets/toolbar/multi_icon_popup_item.dart';

class DummyItemBuilder extends StatelessWidget {
  const DummyItemBuilder(
    this.item,
  );
  final PopupContextItem item;
  @override
  Widget build(BuildContext context) {
    return RiveTheme(
      child: Builder(
        builder: (context) => item.itemBuilder(context, true),
      ),
    );
  }
}

void main() {
  group('Separator', () {
    test('Separator Context item is a separator', () {
      final contextItem = PopupContextItem.separator();
      expect(contextItem.isSeparator, true);
    });

    testWidgets('Separator Context item is a simple widget', (tester) async {
      final widget = DummyItemBuilder(PopupContextItem.separator());

      await tester.pumpWidget(widget);
      expect(find.byType(Container), findsOneWidget);
    });
  });
}
