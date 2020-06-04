import 'package:cursor/propagating_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/rive/managers/revision_manager.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_list_view.dart';
import 'package:rive_editor/widgets/inspector/inspector_pill_button.dart';

class RevisionHistoryPanel extends StatelessWidget {
  final RevisionManager manager;

  const RevisionHistoryPanel({
    @required this.manager,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ValueStreamBuilder<RevisionDM>(
            stream: manager.selectedRevision,
            builder: (context, snapshot) => InspectorPillButton(
              label: 'Edit Current Revision',
              press: snapshot.hasData
                  ? () => ActiveFile.find(context)
                      .restoreRevision(manager.selectedRevision.value)
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
          ),
          child: InspectorPillButton(
              label: 'Cancel',
              press: () => ActiveFile.find(context).hideRevisionHistory()),
        ),
        Separator(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 20,
          ),
          color: theme.colors.inspectorSeparator,
        ),
        ValueStreamBuilder<List<RevisionDM>>(
          stream: manager.list,
          builder: (context, snapshot) => !snapshot.hasData
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : Expanded(
                  child: InspectorListView(
                    itemBuilder: (context, index) => _RevisionItem(
                      manager: manager,
                      model: snapshot.data[index],
                    ),
                    itemCount: snapshot.data.length,
                  ),
                ),
        ),
      ],
    );
  }
}

class _RevisionItem extends StatefulWidget {
  final RevisionDM model;
  final RevisionManager manager;

  const _RevisionItem({
    Key key,
    this.model,
    this.manager,
  }) : super(key: key);

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'June',
    'July',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  __RevisionItemState createState() => __RevisionItemState();
}

class __RevisionItemState extends State<_RevisionItem> {
  bool _hover = false;
  String _formatDate(DateTime dateTime) {
    var hour = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString()
        .padLeft(2, '0');
    var minute = dateTime.minute.toString().padLeft(2, '0');
    return '${_RevisionItem._months[dateTime.month - 1]} ${dateTime.day} - '
        '$hour:$minute ${dateTime.hour >= 12 ? 'pm' : 'am'}';
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);
    return PropagatingListener(
      onPointerDown: (_) {
        widget.manager.select.add(widget.model);
      },
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _hover = true;
          });
        },
        onExit: (_) {
          setState(() {
            _hover = false;
          });
        },
        child: ValueStreamBuilder<RevisionDM>(
          stream: widget.manager.selectedRevision,
          builder: (context, snapshot) {
            bool isSelected = snapshot.data == widget.model;
            return Container(
              margin: const EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: 10,
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                _formatDate(widget.model.updated),
                style: isSelected
                    ? theme.textStyles.inspectorWhiteLabel
                    : theme.textStyles.inspectorPropertyLabel,
              ),
              decoration: BoxDecoration(
                //
                color: isSelected
                    ? theme.colors.selectedRevision
                    : _hover ? theme.colors.hoveredRevision : null,
                borderRadius: const BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
