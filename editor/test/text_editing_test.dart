import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/common/rive_text_form_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class DummyItemBuilder extends StatelessWidget {
  const DummyItemBuilder(
    this.item,
  );
  final RiveTextFormField item;
  @override
  Widget build(BuildContext context) {
    return RiveTheme(
      child: MaterialApp(
        home: Scaffold(
          body: item,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('Check initial value of Text Field', (tester) async {
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '-',
      onComplete: (value, isDragging) {},
    ));
    await tester.pumpWidget(widget);
    expect(find.text('-'), findsOneWidget);
  });
}
