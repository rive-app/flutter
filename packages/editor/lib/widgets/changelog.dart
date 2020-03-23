import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';

class ChangeLog extends StatefulWidget {
  const ChangeLog({Key key}) : super(key: key);

  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  Future<String> _markdown;

  @override
  void initState() {
    // markdown = rootBundle.loadString('assets/changelog/changelog.md');
    _markdown = _fetchChangelog();
    super.initState();
  }

  /// Fetches the changelog from a URL
  Future<String> _fetchChangelog() async {
    final res =
        await http.get('https://cdn.rive.app/changelogs/stryker/changelog.md');
    if (res.statusCode == 200) {
      return res.body;
    }
    return 'Unable to access changelog';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder(
        future: _markdown,
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
