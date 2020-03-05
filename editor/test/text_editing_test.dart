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
  testWidgets('Check initial value', (tester) async {
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '-',
      onComplete: (value, isDragging) {},
    ));
    await tester.pumpWidget(widget);
    expect(find.text('-'), findsOneWidget);
  });

  testWidgets('Check initial value with show degree', (tester) async {
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '-',
      showDegree: true,
      onComplete: (value, isDragging) {},
    ));
    await tester.pumpWidget(widget);
    expect(find.text('-'), findsOneWidget);
    expect(find.text('-°'), findsNothing);
  });

  testWidgets('Check that all text is selected when focused', (tester) async {
    final controller = TextEditingController();
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '1234',
      onComplete: (value, isDragging) {},
      controller: controller,
    ));
    await tester.pumpWidget(widget);
    expect(find.text('1234'), findsOneWidget);
    await tester.tap(find.text('1234'));
    expect(
      controller.selection,
      TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      ),
    );
  });

  testWidgets('Expect Value after remove focus', (tester) async {
    final focusNode = FocusNode();
    String _savedValue;
    bool _isDragging;
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '5678',
      onComplete: (value, isDragging) {
        _savedValue = value;
        _isDragging = isDragging;
      },
      focusNode: focusNode,
    ));
    await tester.pumpWidget(widget);
    expect(find.text('5678'), findsOneWidget);
    await tester.tap(find.text('5678'));
    focusNode.unfocus();
    await tester.pumpWidget(widget);
    expect(_savedValue == '5678', true);
    expect(_isDragging, false);
  });

  testWidgets('Expect Previous Value after remove focus and clear text',
      (tester) async {
    final focusNode = FocusNode();
    final controller = TextEditingController();
    String _savedValue;
    bool _isDragging;
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '1356',
      onComplete: (value, isDragging) {
        _savedValue = value;
        _isDragging = isDragging;
      },
      focusNode: focusNode,
      controller: controller,
    ));
    await tester.pumpWidget(widget);
    expect(find.text('1356'), findsOneWidget);
    await tester.tap(find.text('1356'));
    focusNode.unfocus();
    controller.clear();
    await tester.pumpWidget(widget);
    expect(_savedValue == '1356', true);
    expect(_isDragging, false);
  });

  testWidgets('Expect New Value after remove focus', (tester) async {
    final focusNode = FocusNode();
    String _savedValue;
    bool _isDragging;
    final widget = DummyItemBuilder(RiveTextFormField(
      initialValue: '1356',
      onComplete: (value, isDragging) {
        _savedValue = value;
        _isDragging = isDragging;
      },
      focusNode: focusNode,
    ));
    await tester.pumpWidget(widget);
    expect(find.text('1356'), findsOneWidget);
    await tester.tap(find.text('1356'));
    await tester.enterText(find.byType(RiveTextFormField), '123456');
    focusNode.unfocus();
    await tester.pumpWidget(widget);
    expect(_savedValue == '123456', true);
    expect(_isDragging, false);
  });
}
