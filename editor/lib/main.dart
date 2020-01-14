import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/node.dart';
import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/popup/popup_button.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'widgets/files_view/file.dart';
import 'widgets/files_view/folder.dart';
import 'widgets/files_view/view.dart';
import 'widgets/hierarchy.dart';
import 'widgets/path_widget.dart';
import 'widgets/popup/context_popup.dart';
import 'widgets/profile_view.dart';
import 'widgets/resize_panel.dart';

import 'package:window_utils/window_utils.dart';
// import 'package:rive_core/rive_file.dart';
// import 'package:core/coop/connect_result.dart';

import 'package:provider/provider.dart';

import 'widgets/tab_bar/rive_tab_bar.dart';

// var file = RiveFile("102:15468");

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
    // Instance the app context.
    var rive = Rive();

    // Fake load a test file.
    rive.open("test");
    return CursorView(
      child: MultiProvider(
        providers: [
          Provider.value(value: rive),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Editor(),
        ),
      ),
    );
  }
}

// Just some fake tabs to test the widgets.
var tabs = [
  RiveTabItem(name: "Guido's Files", closeable: false),
  RiveTabItem(name: "Ellipse Testing"),
  RiveTabItem(name: "Spaceman"),
];

// Hacky way to track which tab is selected (just for testing).
int selectedTab = 1;

// Testing context menu items.
List<ContextItem<Rive>> contextItems = [
  ContextItem(
    "Artboard",
    select: (Rive rive) {
      var artboard = Artboard()..name = "New Artboard";
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
    return Material(
      child: Column(
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
          Expanded(child: _buildBody(context))
        ],
      ),
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
    const kProfileWidth = 280.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: FilesView(
            folders: [
              FolderItem(
                key: ValueKey("001"),
                name: "2D Characters",
              ),
              FolderItem(
                key: ValueKey("002"),
                name: "Sample Characters",
              ),
              FolderItem(
                key: ValueKey("003"),
                name: "Quanta Tests",
              ),
              FolderItem(
                key: ValueKey("004"),
                name: "Partical Systems",
              ),
              FolderItem(
                selected: true,
                key: ValueKey("005"),
                name: "Raiders of Odin",
              ),
            ],
            files: [
              FileItem(
                selected: true,
                key: ValueKey("001"),
                name: "Dragon",
                image: "https://www.lunapic.com/editor/premade/transparent.gif",
              ),
              FileItem(
                key: ValueKey("002"),
                name: "Flossy",
                image:
                    "http://www.pngmart.com/files/10/Dog-Looking-PNG-Transparent-Picture.png",
              ),
              FileItem(
                key: ValueKey("003"),
                name: "The Kid",
                image:
                    "http://www.pngmart.com/files/9/Marvel-Thanos-PNG-Free-Download.png",
              ),
              FileItem(
                key: ValueKey("004"),
                name: "Yellow Mech",
                image:
                    "https://webstockreview.net/images/clipart-baby-sea-otter-13.png",
              ),
            ],
          ),
        ),
        Container(
          width: kProfileWidth,
          color: ThemeUtils.backgroundLightGrey,
          child: Padding(
            padding: EdgeInsets.only(bottom: 20.0, top: 20.0),
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
