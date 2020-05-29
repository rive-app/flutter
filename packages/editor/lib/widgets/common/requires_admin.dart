import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';

/// A widget that only displays its children if the user is an admin

class RequiresAdmin extends StatelessWidget {
  const RequiresAdmin({Key key, this.child}) : super(key: key);
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder(
      stream: Plumber().getStream<Me>(),
      builder: (context, snapshot) => (snapshot.hasData &&
              snapshot.data?.isAdmin != null &&
              snapshot.data.isAdmin)
          ? child
          : const SizedBox(),
    );
  }
}
