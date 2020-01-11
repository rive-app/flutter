import 'package:flutter/material.dart';
import 'package:rive_core/node.dart';
import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'widgets/hierarchy.dart';
import 'widgets/popup/context_popup.dart';
import 'widgets/resize_panel.dart';

import 'package:window_utils/window_utils.dart';
import 'package:rive_core/rive_file.dart';
// import 'package:core/coop/connect_result.dart';

import 'package:provider/provider.dart';

import 'widgets/tab_bar/rive_tab_bar.dart';

var file = RiveFile("102:15468");

Node node;
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => WindowUtils.hideTitleBar(),
  );
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
  @override
  Widget build(BuildContext context) {
    var rive = Rive();
    rive.open("test");
    return CursorView(
      child: MultiProvider(
        providers: [
          Provider.value(value: rive),
          ChangeNotifierProvider.value(value: rive.file),
          ChangeNotifierProvider.value(value: rive.treeController)
        ],
        child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Scaffold(
            body: Editor(),
          ),
        ),
      ),
    );
  }
}

var tabs = [
  RiveTabItem(name: "Guido's Files", closeable: false),
  RiveTabItem(name: "Ellipse Testing"),
  RiveTabItem(name: "Spaceman"),
];

int selectedTab = 1;

List<ContextItem> contextItems = [
  ContextItem("Artboard", select:()=>print("Make artboard...")),
  ContextItem("Node", select:()=>print("Make node...")),
  ContextItem.separator(),
  ContextItem("Shape", select:()=>print("SELECT SHAPE!")),
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
              RiveTabBar(
                offset: 95,
                tabs: tabs,
                selected: tabs[selectedTab],
                select: (tab) {
                  // Hackity hack to test the tabs.
                  selectedTab = tabs.indexOf(tab);
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(5),
          height: 42,
          color: Color.fromRGBO(60, 60, 60, 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PopupButton(
                builder: (context) {
                  return Container(
                    margin:
                        EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 5),
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
                itemBuilder: (context, item, isHovered) => item
                    .itemBuilder(context,
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
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              ResizePanel(
                direction: ResizeDirection.horizontal,
                side: ResizeSide.end,
                min: 300,
                max: 500,
                child: Container(
                  color: Color.fromRGBO(50, 50, 50, 1.0),
                  child: ExampleTreeView(),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    ResizePanel(
                      direction: ResizeDirection.vertical,
                      side: ResizeSide.end,
                      min: 100,
                      max: 500,
                      child: Container(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: Color.fromRGBO(29, 29, 29, 1.0),
                      ),
                    ),
                    ResizePanel(
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
