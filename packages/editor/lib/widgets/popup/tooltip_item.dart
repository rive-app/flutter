import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';

class TooltipItem extends PopupListItem {
  /// Text label to show in the row for this tooltip item.
  final String name;

  @override
  bool get canSelect => false;

  @override
  double get height => 25;

  @override
  List<PopupListItem> get popup => null;

  @override
  ChangeNotifier get rebuildItem => null;

  @override
  final SelectCallback select = null;

  TooltipItem(this.name);

  Widget itemBuilder(BuildContext context) {
    return Center(
        child: Text(name, style: RiveTheme.of(context).textStyles.tooltipText));
  }
}
