import 'package:cursor/cursor_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:window_utils/window_utils.dart';

import 'rive/hierarchy_tree_controller.dart';
import 'rive/rive.dart';
import 'rive/stage/stage.dart';
import 'widgets/files_view/screen.dart';
import 'widgets/hierarchy.dart';
import 'widgets/popup/context_popup.dart';
import 'widgets/popup/popup_button.dart';
import 'widgets/resize_panel.dart';
import 'widgets/stage_view.dart';
import 'widgets/tab_bar/rive_tab_bar.dart';

// var file = RiveFile("102:15468");

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => WindowUtils.hideTitleBar(),
  );
  // Fake load a test file.
  rive.fileBrowser.init(rive);
  rive.open("100/100");

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

final focusNode = FocusNode();

// Testing context menu items.

const double resizeEdgeSize = 10;

List<ContextItem<Rive>> contextItems = [
  ContextItem(
    "Artboard",
    select: (Rive rive) {
      // var artboard =
      //     rive.file.value.makeCoreInstance(ArtboardBase.typeKey) as Artboard;
      // var artboard = Artboard()
      //   ..name = "New Artboard"
      //   ..x = 0
      //   ..y = 0
      //   ..width = 200
      //   ..height = 100;
      // rive.file.value.add(artboard);
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

Node node;

var rive = Rive();

// Just some fake tabs to test the widgets.
int selectedTab = 1;

// Hacky way to track which tab is selected (just for testing).
final tabs = [
  RiveTabItem(name: "Guido's Files", closeable: false),
  RiveTabItem(name: "Ellipse Testing"),
  RiveTabItem(name: "Spaceman"),
];

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var focusScope = FocusScope.of(context);

    return CursorView(
      child: MultiProvider(
        providers: [
          Provider.value(value: rive),
        ],
        child: MaterialApp(
          // shortcuts: {
          //   LogicalKeySet.fromSet({LogicalKeyboardKey.meta}): Actio
          // },
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          // darkTheme: ThemeData.dark(),
          // themeMode: ThemeMode.light,
          home: DefaultTextStyle(
            style: TextStyle(fontFamily: "Roboto-Regular", fontSize: 13),
            child: Container(
              child: Scaffold(
                body: RawKeyboardListener(
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
                    autofocus: true,
                    focusNode: focusNode),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Testing context menu items.
class Editor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 39,
          color: const Color.fromRGBO(50, 50, 50, 1.0),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      WindowUtils.startDrag();
                    }),
              ),
              ValueListenableBuilder<List<RiveTabItem>>(
                valueListenable: rive.tabs,
                builder: (context, tabs, child) {
                  return ValueListenableBuilder<RiveTabItem>(
                    valueListenable: rive.selectedTab,
                    builder: (context, selectedTab, child) => RiveTabBar(
                      offset: 95,
                      tabs: tabs,
                      selected: selectedTab,
                      select: rive.openTab,
                      close: rive.closeTab,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<RiveTabItem>>(
            valueListenable: rive.tabs,
            builder: (context, tabs, child) =>
                ValueListenableBuilder<RiveTabItem>(
              valueListenable: rive.selectedTab,
              builder: (context, tab, child) =>
                  _buildBody(context, tabs.indexOf(tab)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBody(BuildContext context, int index) {
    switch (index) {
      case 0:
        return FilesView();
      default:
        return _buildEditor(context);
    }
  }

  Widget _buildEditor(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(5),
          height: 42,
          color: const Color.fromRGBO(60, 60, 60, 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<Rive>(
                builder: (context, rive, _) => PopupButton(
                  selectArg: rive,
                  builder: (context) {
                    return Container(
                      margin: const EdgeInsets.only(
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
              const Expanded(
                child: StagePanel(),
              ),
              /*Expanded(
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
              ),*/
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
        builder: (context, rive, _) => ValueListenableBuilder<Stage>(
          valueListenable: rive.stage,
          builder: (context, stage, _) => Stack(
            children: [
              Positioned.fill(
                child: stage == null
                    ? Container()
                    : StageView(
                        rive: rive,
                        stage: stage,
                      ),
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
                    stage.mouseExit(details.buttons, local.dx, local.dy);
                  },
                  onHover: (details) {
                    RenderBox getBox = context.findRenderObject() as RenderBox;
                    var local = getBox.globalToLocal(details.position);
                    stage.mouseMove(details.buttons, local.dx, local.dy);
                    // print("MOVE $local");
                  },
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerSignal: (details) {
                      if (details is PointerScrollEvent) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseWheel(local.dx, local.dy,
                            details.scrollDelta.dx, details.scrollDelta.dy);
                      }
                    },
                    onPointerDown: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      stage.mouseDown(details.buttons, local.dx, local.dy);
                      // print("POINTER DOWN ${local}");
                    },
                    onPointerUp: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      stage.mouseUp(details.buttons, local.dx, local.dy);
                      // print("POINTER UP ${local}");
                    },
                    onPointerMove: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      stage.mouseDrag(details.buttons, local.dx, local.dy);
                      // print("POINTER DRAG ${local}");
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
