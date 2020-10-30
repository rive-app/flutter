import 'dart:convert';

// ignore: unused_import
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      home: MyHomePage(title: 'Original SVG reader'),
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
        // .where((String key) => key.contains('custom'))
        // .where((String key) => key.contains('mini'))
        // .where((String key) => key.contains('sde'))
        // .where((String key) => key.contains('club'))
        // .where((String key) => key.contains('blob.'))
        // .where((String key) => key.contains('.svg'))
        // .where((String key) => key.contains('avatar.clean'))
        // .where((String key) => key.contains('mini_hulk'))
        .where((String key) => key.contains('custom'))
        // .where((String key) => key.contains('mask_check'))
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
                decoration: const BoxDecoration(color: Colors.black),
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
                style: const TextStyle(color: Colors.white)),
            Expanded(child: _svgPicture),
          ]);
  }
}
