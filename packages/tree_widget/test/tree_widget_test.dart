import 'package:flutter/material.dart';
import 'package:flutter/src/gestures/drag_details.dart';
import 'package:flutter/src/gestures/events.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tree_widget/flat_tree_item.dart';
import 'package:tree_widget/tree_controller.dart';
import 'package:tree_widget/tree_widget.dart';

class TreeItem {
  final String name;
  final List<TreeItem> children;

  const TreeItem(this.name, {this.children});
}

class PropertyTreeItem extends TreeItem {
  const PropertyTreeItem(String name, {List<TreeItem> children})
      : super(name, children: children);
}

class MyTreeController extends TreeController<TreeItem> {
  MyTreeController(List<TreeItem> data) : super(data);

  @override
  List<TreeItem> childrenOf(TreeItem treeItem) {
    return treeItem.children;
  }

  @override
  bool isDisabled(TreeItem treeItem) {
    return false;
  }

  @override
  bool isProperty(TreeItem treeItem) {
    return treeItem is PropertyTreeItem;
  }

  @override
  int spacingOf(TreeItem treeItem) {
    return 1;
  }

  @override
  void drop(FlatTreeItem<TreeItem> target, DropState state,
      List<FlatTreeItem<TreeItem>> items) {}

  @override
  List<FlatTreeItem<TreeItem>> onDragStart(
      DragStartDetails details, FlatTreeItem<TreeItem> item) {
    return [];
  }

  @override
  void onMouseEnter(PointerEnterEvent event, FlatTreeItem<TreeItem> item) {}

  @override
  void onMouseExit(PointerExitEvent event, FlatTreeItem<TreeItem> item) {}

  @override
  void onTap(FlatTreeItem<TreeItem> item) {}
}

void main() {
  TreeItem treeRoot;

  setUp(() {
    treeRoot = const TreeItem(
      'Artboard',
      children: [
        TreeItem('Group'),
        TreeItem('body'),
        TreeItem('neck'),
        TreeItem('arm_right'),
        TreeItem('head'),
        TreeItem('arm_left'),
        TreeItem('root', children: [
          TreeItem('ik_head', children: [
            PropertyTreeItem('Translation Constraint'),
            TreeItem('neck'),
          ]),
          TreeItem('ctrl_foot_left'),
          TreeItem('ctrl_foot_right'),
        ]),
        TreeItem('leg_left'),
        TreeItem('leg_right'),
      ],
    );
  });

  group('Tree Tests', () {
    test('test tree flattening', () {
      final data = [treeRoot];
      final controller = MyTreeController(data);

      controller.flatten();
      controller.expand(data[0]);
      controller.expand(data[0].children[6]);
      expect(controller.flat.length, 13);
    });
  });

  group('Widget Tests', () {
    testWidgets('Instantiate a TreeView widget', (tester) async {
      final data = [treeRoot];
      final controller = MyTreeController(data);

      // Tree should start with only one item viewable
      controller.flatten();
      expect(controller.flat.length, 1);

      final treeWidget = TreeView<TreeItem>(
        controller: controller,
        expanderBuilder: (context, item, style) => Container(),
        itemBuilder: (context, item, style) => Text(item.data.name),
        iconBuilder: (context, item, style) => Container(),
      );

      final wrappedWidget = MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: treeWidget,
        ),
      );

      await tester.pumpWidget(wrappedWidget);
      expect(find.text('Artboard'), findsOneWidget);
    });

    testWidgets('TreeView widget displays an item\'s icon', (tester) async {
      final data = [treeRoot];
      final controller = MyTreeController(data)..flatten();

      final iconWidget = Icon(Icons.block);

      final treeWidget = TreeView<TreeItem>(
        controller: controller,
        expanderBuilder: (context, item, style) => Container(),
        itemBuilder: (context, item, style) => Text(item.data.name),
        iconBuilder: (context, item, style) => iconWidget,
      );

      final wrappedWidget = MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: treeWidget,
        ),
      );

      await tester.pumpWidget(wrappedWidget);
      expect(find.byWidget(iconWidget), findsOneWidget);
    });

    testWidgets('TreeView widget can be expanded', (tester) async {
      final data = [treeRoot];
      final controller = MyTreeController(data);

      // Tree should start with only one item viewable
      controller.flatten();
      expect(controller.flat.length, 1);

      // Expand the root tree
      controller.expand(treeRoot);
      // Ten items should now be visible
      expect(controller.flat.length, 10);
      controller.flatten();

      final treeWidget = TreeView<TreeItem>(
        controller: controller,
        expanderBuilder: (context, item, style) => Container(),
        itemBuilder: (context, item, style) => Text(item.data.name),
        iconBuilder: (context, item, style) => Container(),
      );

      final wrappedWidget = MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: treeWidget,
        ),
      );

      await tester.pumpWidget(wrappedWidget);
      expect(find.text('head'), findsOneWidget);
      expect(find.text('leg_left'), findsOneWidget);
      expect(find.text('leg_right'), findsOneWidget);
      expect(find.text('arm_left'), findsOneWidget);
      expect(find.text('arm_right'), findsOneWidget);
    });
  });
}
