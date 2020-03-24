import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ChangeLog extends StatefulWidget {
  const ChangeLog({Key key}) : super(key: key);

  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  Future<String> _markdown;

  @override
  void initState() {
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
  void didUpdateWidget(ChangeLog oldWidget) {
    // Update the changelog
    // _fetchChangelog();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RiveTheme.of(context).colors.fileBackgroundLightGrey,
      child: Center(
        child: Container(
          width: 600,
          child: FutureBuilder(
            future: _markdown,
            builder: (context, AsyncSnapshot<String> snapshot) {
              if (snapshot.hasData) {
                return Markdown(data: snapshot.data);
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
