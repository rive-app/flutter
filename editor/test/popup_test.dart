import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/popup/context_popup.dart';

class DummyItemBuilder extends StatelessWidget {
  const DummyItemBuilder(
    this.item,
  );
  final PopupContextItem item;
  @override
  Widget build(BuildContext context) {
    return item.itemBuilder(context, true);
  }
}

void main() {
  testWidgets('Seperator Context item is a seperator', (tester) async {
    final contextItem = PopupContextItem.separator();
    expect(contextItem.isSeparator, true);
  });

  testWidgets('Seperator Context item is a simple widget', (tester) async {
    final widget = DummyItemBuilder(PopupContextItem.separator());

    await tester.pumpWidget(widget);
    expect(find.byType(Container), findsOneWidget);
  });
}
