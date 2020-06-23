import 'package:cursor/propagating_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

// Handy way to screenshot a widget:
//
// var image = await captureImage(elements.single);
// final ByteData bytes =
//     await image.toByteData(format: ui.ImageByteFormat.png);
// var imageFile = File('test.png');
// imageFile.writeAsBytesSync(bytes.buffer.asUint8List(), flush: true);

/// Builds up an inspector panel based on what is selected in [file].
class TestInspector extends StatefulWidget {
  final OpenFileContext file;

  const TestInspector({
    Key key,
    this.file,
  }) : super(key: key);

  @override
  _TestInspectorState createState() => _TestInspectorState();
}

class _TestInspectorState extends State<TestInspector> {
  RiveIconCache _iconCache;
  Rive _rive;
  @override
  void initState() {
    _iconCache = RiveIconCache(rootBundle);
    _rive = Rive(
      iconCache: _iconCache,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: UIStrings(
          child: RiveTheme(
            child: RiveContext(
              rive: _rive,
              child: TipRoot(
                context: TipContext(),
                child: ImageCacheProvider(
                  manager: ImageManager(),
                  child: IconCache(
                    cache: _iconCache,
                    child: PropagatingListenerRoot(
                      child: ActiveFile(
                        file: widget.file,
                        child: const InspectorPanel(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
