import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'rive/file_browser/file.dart';
import 'rive/file_browser/folder.dart';
import 'widgets/files_view/view.dart';
import 'widgets/hierarchy.dart';
import 'widgets/popup/context_popup.dart';
import 'widgets/profile_view.dart';
import 'widgets/resize_panel.dart';

import 'package:window_utils/window_utils.dart';
// import 'package:rive_core/rive_file.dart';
// import 'package:core/coop/connect_result.dart';

import 'package:provider/provider.dart';

import 'widgets/stage_view.dart';
import 'widgets/tab_bar/rive_tab_bar.dart';

// var file = RiveFile("102:15468");

const double resizeEdgeSize = 10;
Node node;

var rive = Rive();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => WindowUtils.hideTitleBar(),
  );
  // Fake load a test file.
  rive.open("test");
  rive.fileBrowser.init();

  // print("CONNECTING");
  // file.connect('ws://localhost:8000/').then((result) {
  //   // if(file.isAvailable){

  //   // }
  //   print("CONNECTED $result");
  //   if (result != ConnectResult.connected) {
  //     return;
  //   }
  //   node = file.add(Node()..name = 'test');
  //   node.name = 'My Shiny Node';
  //   file.captureJournalEntry();
  //   runApp(MyApp());
  // });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    var focusScope = FocusScope.of(context);

    return CursorView(
      child: MultiProvider(
        providers: [
          Provider.value(value: rive),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: DefaultTextStyle(
            style: TextStyle(fontFamily: "Roboto-Regular"),
            child: Scaffold(
              body: Listener(
                onPointerDown: (details) => focusNode.requestFocus(),
                child: RawKeyboardListener(
                  autofocus: true,
                  focusNode: focusNode,
                  onKey: (event) {
                    var primary = FocusManager.instance.primaryFocus;
                    rive.onKeyEvent(
                        event,
                        primary != focusNode &&
                            focusScope.nearestScope != primary);
                    // print("PRIMARY $primary");
                    // if (primary == focusNode ||
                    //     focusScope.nearestScope == primary) {
                    //   print("Key ${event}");
                    //   return;
                    // }
                    // print("NO FOCUS");
                  },
                  child: Editor(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Hacky way to track which tab is selected (just for testing).
int selectedTab = 1;

// Testing context menu items.
List<ContextItem<Rive>> contextItems = [
  ContextItem(
    "Artboard",
    select: (Rive rive) {
      var artboard = Artboard()
        ..name = "New Artboard"
        ..x = 0
        ..y = 0
        ..width = 200
        ..height = 100;
      rive.file.value.add(artboard);
    },
  ),
  ContextItem("Node", select: (rive) => print("Make node...")),
  ContextItem.separator(),
  ContextItem("Shape", select: (rive) => print("SELECT SHAPE!")),
  ContextItem("Pen", shortcut: "P"),
  ContextItem.separator(),
  ContextItem("Artboard", shortcut: "A"),
  ContextItem("Bone", shortcut: "B"),
  ContextItem("Node", shortcut: "G"),
  ContextItem("Solo", shortcut: "Y")
];

class Editor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 39,
          color: Color.fromRGBO(50, 50, 50, 1.0),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      WindowUtils.startDrag();
                    }),
              ),
              Builder(
                builder: (_) {
                  // Just some fake tabs to test the widgets.
                  var tabs = [
                    RiveTabItem(name: "Guido's Files", closeable: false),
                  ];
                  final _rive = Provider.of<Rive>(context);
                  tabs.addAll(_rive.openFiles
                      .map((f) => RiveTabItem(name: f))
                      .toList());
                  return RiveTabBar(
                    offset: 95,
                    tabs: tabs,
                    selected: tabs[selectedTab],
                    select: (tab) {
                      // Hackity hack to test the tabs.
                      selectedTab = tabs.indexOf(tab);
                      (context as Element).markNeedsBuild();
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context))
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (selectedTab) {
      case 0:
        return _buildFiles(context);
      default:
        return _buildEditor(context);
    }
  }

  Widget _buildFiles(BuildContext context) {
    const kProfileWidth = 215.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: FilesView(),
        ),
        Container(
          width: kProfileWidth,
          color: ThemeUtils.backgroundLightGrey,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: ProfileView(),
          ),
        ),
      ],
    );
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(5),
          height: 42,
          color: Color.fromRGBO(60, 60, 60, 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<Rive>(
                builder: (context, rive, _) => PopupButton(
                  selectArg: rive,
                  builder: (context) {
                    return Container(
                      margin: EdgeInsets.only(
                          left: 10, right: 10, top: 5, bottom: 5),
                      child: Center(
                        child: Text(
                          "Add",
                          style: TextStyle(
                            fontFamily: 'Roboto-Regular',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                  items: contextItems,
                  itemBuilder: (context, item, isHovered) => item.itemBuilder(
                      context,
                      isHovered) /*(
                child: Text(
                  "Item $index",
                  style: TextStyle(
                    fontFamily: 'Roboto-Regular',
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              )*/
                  ,
                  itemSelected: (context, index) {},
                ),
              ),
              Container(
                width: 100,
                child: TextField(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.end,
                min: 300,
                max: 500,
                child: Container(
                  color: Color.fromRGBO(50, 50, 50, 1.0),
                  child: Consumer<Rive>(
                    builder: (context, rive, _) =>
                        ValueListenableBuilder<HierarchyTreeController>(
                      valueListenable: rive.treeController,
                      builder: (context, controller, _) =>
                          HierarchyTreeView(controller: controller),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    ResizePanel(
                      hitSize: resizeEdgeSize,
                      direction: ResizeDirection.vertical,
                      side: ResizeSide.end,
                      min: 100,
                      max: 500,
                      child: Container(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                    Expanded(
                      child: StagePanel(),
                    ),
                    ResizePanel(
                      hitSize: resizeEdgeSize,
                      direction: ResizeDirection.vertical,
                      side: ResizeSide.start,
                      min: 100,
                      max: 500,
                      child: Container(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.start,
                min: 300,
                max: 500,
                child: Container(
                  color: Color.fromRGBO(50, 50, 50, 1.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StagePanel extends StatelessWidget {
  const StagePanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.fromRGBO(29, 29, 29, 1.0),
      child: Consumer<Rive>(
        builder: (context, rive, _) => Stack(
          children: [
            Positioned.fill(
              child: StageView(rive),
            ),
            Positioned(
              left: resizeEdgeSize,
              top: resizeEdgeSize,
              bottom: resizeEdgeSize,
              right: resizeEdgeSize,
              child: MouseRegion(
                opaque: true,
                onExit: (details) {
                  RenderBox getBox = context.findRenderObject() as RenderBox;
                  var local = getBox.globalToLocal(details.position);
                  rive.stage.mouseExit(details.buttons, local.dx, local.dy);
                },
                onHover: (details) {
                  RenderBox getBox = context.findRenderObject() as RenderBox;
                  var local = getBox.globalToLocal(details.position);
                  rive.stage.mouseMove(details.buttons, local.dx, local.dy);
                  // print("MOVE $local");
                },
                child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerSignal: (details) {
                      if (details is PointerScrollEvent) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        rive.stage.mouseWheel(local.dx, local.dy,
                            details.scrollDelta.dx, details.scrollDelta.dy);
                      }
                    },
                    onPointerDown: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      rive.stage.mouseDown(details.buttons, local.dx, local.dy);
                      // print("POINTER DOWN ${local}");
                    },
                    onPointerUp: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      rive.stage.mouseUp(details.buttons, local.dx, local.dy);
                      // print("POINTER UP ${local}");
                    },
                    onPointerMove: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      rive.stage.mouseDrag(details.buttons, local.dx, local.dy);
                      // print("POINTER DRAG ${local}");
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
