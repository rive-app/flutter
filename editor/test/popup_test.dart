import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';

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
  testWidgets('Separator Context item is a separator', (tester) async {
    final contextItem = PopupContextItem.separator();
    expect(contextItem.isSeparator, true);
  });

  testWidgets('Separator Context item is a simple widget', (tester) async {
    final widget = DummyItemBuilder(PopupContextItem.separator());

    await tester.pumpWidget(widget);
    expect(find.byType(Container), findsOneWidget);
  });
}
