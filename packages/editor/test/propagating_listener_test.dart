import 'package:cursor/cursor_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cursor/propagating_listener.dart';

void main() {
  testWidgets('Input events propagate', (tester) async {
    bool clickedCursorView = false;
    bool clickedText = false;

    final widget = MaterialApp(
      home: CursorView(
        onPointerDown: (_) {
          clickedCursorView = true;
        },
        child: PropagatingListener(
          behavior: HitTestBehavior.deferToChild,
          child: Container(
            child: const Text('click me'),
          ),
          onPointerDown: (_) {
            clickedText = true;
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);

    await tester.press(find.text('click me'));

    // wait for the events to process (this is due to us using a timer to reset
    // event data).
    await tester.pumpAndSettle();

    // Clicking on 'click me' should allow both cursor view and text listeners
    // to receive the event.
    expect(clickedCursorView, true);
    expect(clickedText, true);
  });

  testWidgets('Input events can prevent propagation', (tester) async {
    bool clickedCursorView = false;
    bool clickedText = false;

    final widget = MaterialApp(
      home: CursorView(
        onPointerDown: (_) {
          clickedCursorView = true;
        },
        child: PropagatingListener(
          behavior: HitTestBehavior.deferToChild,
          child: Container(
            child: const Text('click me'),
          ),
          onPointerDown: (event) {
            clickedText = true;
            // This should prevent the cursor view from receiving the
            // onPointerDown.
            event.stopPropagation();
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);

    await tester.press(find.text('click me'));

    // wait for the events to process (this is due to us using a timer to reset
    // event data).
    await tester.pumpAndSettle();

    // Clicking on 'click me' should allow only the text listener
    // to receive the event.
    expect(clickedCursorView, false);
    expect(clickedText, true);
  });

  testWidgets('Input events can prevent deep propagation', (tester) async {
    bool clickedCursorView = false;
    bool clickedContainer = false;
    bool clickedText = false;

    final widget = MaterialApp(
      home: CursorView(
        onPointerDown: (_) {
          clickedCursorView = true;
        },
        child: PropagatingListener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            clickedContainer = true;
          },
          child: Container(
            width: 500,
            height: 500,
            child: PropagatingListener(
              behavior: HitTestBehavior.deferToChild,
              child: Container(
                child: const Text('click me'),
              ),
              onPointerDown: (event) {
                clickedText = true;

                event.stopPropagation();
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    await tester.press(find.text('click me'));

    // wait for the events to process (this is due to us using a timer to reset
    // event data).
    await tester.pumpAndSettle();

    // Clicking on 'click me' should allow only the text listener to receive the
    // event. It blocks propagation so no other listeners get it.
    expect(clickedCursorView, false);
    expect(clickedContainer, false);
    expect(clickedText, true);
  });

  testWidgets('Input events can prevent complex propagation', (tester) async {
    bool clickedCursorView = false;
    bool clickedContainer = false;
    bool clickedText = false;

    final widget = MaterialApp(
      home: CursorView(
        onPointerDown: (_) {
          clickedCursorView = true;
        },
        child: PropagatingListener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            clickedContainer = true;
            // This should prevent the cursor view from receiving the
            // onPointerDown.
            event.stopPropagation();
          },
          child: Container(
            width: 500,
            height: 500,
            child: PropagatingListener(
              behavior: HitTestBehavior.deferToChild,
              child: Container(
                child: const Text('click me'),
              ),
              onPointerDown: (event) {
                clickedText = true;
                // Don't block propagation here...
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);

    await tester.press(find.text('click me'));

    // wait for the events to process (this is due to us using a timer to reset
    // event data).
    await tester.pumpAndSettle();

    // Clicking on 'click me' should allow only the text listener to receive the
    // event. It should bubble up to the container which should also receive it.
    // The container then stops propagation so the cursor view should not
    // receive it.
    expect(clickedCursorView, false);
    expect(clickedContainer, true);
    expect(clickedText, true);
  });
}
