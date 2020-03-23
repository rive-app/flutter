import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChangeLog extends StatefulWidget {
  const ChangeLog({Key key}) : super(key: key);

  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  Future<String> markdown;

  @override
  void initState() {
    markdown = rootBundle.loadString('assets/changelog/changelog.md');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: markdown,
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            return Markdown(data: snapshot.data);
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
