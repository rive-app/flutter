import 'dart:convert';

// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rive_core/runtime/runtime_exporter.dart';
import 'package:rive_core/runtime/runtime_header.dart';
import 'package:xml/xml_events.dart' as xml show parseEvents;

import 'package:peon_process/src/helpers/convert_svg.dart';
import 'package:rive/rive.dart' as rive;
import 'package:rive_core/rive_file.dart';

// ignore: implementation_imports
import 'package:flutter_svg/src/svg/parser_state.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> pathList = [];
  var callbacks = <Function>[];

  Future _initImages() async {
    // >> To get paths you need these 2 lines
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');

    final Map<String, dynamic> manifestMap =
        json.decode(manifestContent) as Map<String, dynamic>;

    var imagePaths = manifestMap.keys
        // .where((String key) => key.contains('other'))
        // .where((String key) => !key.contains('club'))
        // .where((String key) => key.contains('blob.'))
        // .where((String key) => key.contains('.svg'))
        .where((String key) => key.contains('krank'))
        .where((String key) => key.contains('.svg'))
        .toList();

    // LIMIT ICONS HERE
    setState(() {
      pathList = imagePaths;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (pathList.isEmpty) {
      _initImages();
    }

    var widgets = <Widget>[];
    // pathList

    pathList.forEach((String path) {
      widgets.add(SvgWidget(assetPath: path));
      widgets.add(SvgConverted(assetPath: path, callbacks: callbacks));
    });

    double extent = 300;
    if (pathList.length < 10) {
      extent = 400;
    }

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Column(
          children: [
            FlatButton(
              onPressed: () {
                callbacks.forEach((callback) {
                  callback();
                });
              },
              child: const Text('Nuke'),
            ),
            Expanded(
              child: Container(
                // width: 600,
                decoration: BoxDecoration(color: Colors.black),
                child: GridView.extent(
                    // shrinkWrap: true,
                    maxCrossAxisExtent: extent,
                    padding: const EdgeInsets.all(4.0),
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    children: widgets),
              ),
            ),
          ],
        ));
  }
}

class SvgWidget extends StatefulWidget {
  final String assetPath;

  const SvgWidget({Key key, this.assetPath}) : super(key: key);
  @override
  _SvgWidgetState createState() => _SvgWidgetState();
}

class _SvgWidgetState extends State<SvgWidget> {
  SvgPicture _svgPicture;

  Future<void> load() async {
    setState(() => _svgPicture = SvgPicture.asset(widget.assetPath));
  }

  @override
  Widget build(BuildContext context) {
    if (_svgPicture == null) {
      load();
    }
    return _svgPicture == null
        ? const SizedBox()
        : Column(children: [
            Text(widget.assetPath.split('/').last,
                style: TextStyle(color: Colors.white)),
            Expanded(child: _svgPicture),
          ]);
  }
}

class SvgConverted extends StatefulWidget {
  final String assetPath;
  final List<Function> callbacks;

  const SvgConverted({Key key, this.assetPath, this.callbacks})
      : super(key: key);
  @override
  _SvgConvertedState createState() => _SvgConvertedState();
}

class _SvgConvertedState extends State<SvgConverted> {
  rive.Artboard _riveArtboard;

  Future<void> convertSvg() async {
    widget.callbacks.add(() {
      _riveArtboard = null;
    });
    rootBundle.loadString(widget.assetPath).then(
      (data) async {
        var drawable = await SvgParserStateRived(
                xml.parseEvents(data), 'bob', svgPathFuncs)
            .parse();
        RiveFile _riveFile = createFromSvg(drawable);
        rive.RiveFile();

        var exporter = RuntimeExporter(
            core: _riveFile, info: RuntimeHeader(ownerId: 1, fileId: 1));
        var uint8data = exporter.export();

        // Load the RiveFile from the binary data.
        print('Written file output to ${widget.assetPath.split('/').last}.riv');
        var outFile = File('${widget.assetPath.split('/').last}.riv');
        outFile.create(recursive: true);
        outFile.writeAsBytesSync(uint8data, flush: true);

        var file = rive.RiveFile();
        try {
          var success = file.import(ByteData.view(uint8data.buffer));
          if (success) {
            // The artboard is the root of the animation and is what gets drawn
            // into the Rive widget.
            var artboard = file.artboards.first;
            setState(() => _riveArtboard = artboard);
          }
        } catch (e) {
          print('oops $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_riveArtboard == null) {
      convertSvg();
    }
    return _riveArtboard == null
        ? const SizedBox()
        : Column(children: [
            const Text('rive', style: TextStyle(color: Colors.white)),
            Expanded(child: rive.Rive(artboard: _riveArtboard)),
          ]);
  }
}
