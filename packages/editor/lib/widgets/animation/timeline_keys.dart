import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/animation/keyed_object_tree_controller.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:tree_widget/flat_tree_item.dart';

class TimelineKeys extends StatefulWidget {
  final RiveThemeData theme;
  final ScrollController verticalScroll;
  final KeyedObjectTreeController treeController;

  const TimelineKeys({
    @required this.theme,
    @required this.verticalScroll,
    @required this.treeController,
    Key key,
  }) : super(key: key);

  @override
  _TimelineKeysState createState() => _TimelineKeysState();
}

class _TimelineKeysState extends State<TimelineKeys> {
  double _scrollOffset = 0;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows = [];

  @override
  void initState() {
    super.initState();
    widget.verticalScroll?.addListener(_onVerticalScrollChanged);
    _onVerticalScrollChanged();
    widget.treeController?.addListener(_onFlatListChanged);
    _onFlatListChanged();
  }

  @override
  void didUpdateWidget(TimelineKeys oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalScroll != widget.verticalScroll) {
      oldWidget.verticalScroll?.removeListener(_onVerticalScrollChanged);
      widget.verticalScroll?.addListener(_onVerticalScrollChanged);
      _onVerticalScrollChanged();
    }
    if (oldWidget.treeController != widget.treeController) {
      oldWidget.treeController?.removeListener(_onFlatListChanged);
      widget.treeController?.addListener(_onFlatListChanged);
      _onFlatListChanged();
    }
  }

  @override
  void dispose() {
    widget.verticalScroll?.removeListener(_onVerticalScrollChanged);
    super.dispose();
  }

  void _onFlatListChanged() {
    setState(() {
      _rows = widget.treeController.flat ?? [];
    });
  }

  void _onVerticalScrollChanged() {
    if (widget.verticalScroll == null) {
      return;
    }
    setState(() {
      _scrollOffset = widget.verticalScroll.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _TimelineKeysRenderer(
      theme: widget.theme,
      verticalScrollOffset: _scrollOffset,
      rows: _rows,
    );
  }
}

class _TimelineKeysRenderer extends LeafRenderObjectWidget {
  final RiveThemeData theme;
  final double verticalScrollOffset;
  final List<FlatTreeItem<KeyHierarchyViewModel>> rows;

  const _TimelineKeysRenderer({
    @required this.theme,
    @required this.verticalScrollOffset,
    @required this.rows,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TimelineKeysRenderObject()
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TimelineKeysRenderObject renderObject) {
    renderObject
      ..theme = theme
      ..verticalScrollOffset = verticalScrollOffset
      ..rows = rows;
    ;
  }

  @override
  void didUnmountRenderObject(
      covariant _TimelineKeysRenderObject renderObject) {
    // Any cleanup to do here?
  }
}

class _TimelineKeysRenderObject extends RenderBox {
  final Paint _bgPaint = Paint();
  final Paint _separatorPaint = Paint();

  RiveThemeData _theme;
  double _verticalScrollOffset;
  List<FlatTreeItem<KeyHierarchyViewModel>> _rows;

  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (_theme == value) {
      return;
    }
    _theme = value;
    _bgPaint.color = theme.colors.timelineBackground;
    _separatorPaint.color = theme.colors.timelineLine;
    markNeedsPaint();
  }

  double get verticalScrollOffset => _verticalScrollOffset;
  set verticalScrollOffset(double value) {
    if (_verticalScrollOffset == value) {
      return;
    }
    _verticalScrollOffset = value;
    markNeedsPaint();
  }

  List<FlatTreeItem<KeyHierarchyViewModel>> get rows => _rows;
  set rows(List<FlatTreeItem<KeyHierarchyViewModel>> value) {
    if (_rows == value) {
      return;
    }
    _rows = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performLayout() {
    super.performLayout();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    canvas.drawRect(offset & size, _bgPaint);
    canvas.save();
    canvas.clipRect(offset & size);

    var rowHeight = theme.treeStyles.timeline.itemHeight;

    var firstRow =
        (_verticalScrollOffset ~/ rowHeight).clamp(0, _rows.length - 1).toInt();
    var renderOffset = _verticalScrollOffset % rowHeight;
    var visibleRows = (size.height / rowHeight).ceil() + 1;
    var lastRow = (firstRow + visibleRows).clamp(0, _rows.length).toInt();

    for (int i = firstRow; i < lastRow; i++) {
      var row = _rows[i].data;

      // We only draw the separator line if it's delineating a component.
      if (row is KeyedComponentViewModel) {
        var rowOffset = i * rowHeight;
        Offset lineStart =
            offset + Offset(0.0, -0.5 - _verticalScrollOffset + rowOffset);

        Offset lineEnd = offset +
            Offset(size.width, -0.5 - _verticalScrollOffset + rowOffset);
        canvas.drawLine(lineStart, lineEnd, _separatorPaint);
      }
    }

    // for (int i = 0; i < 10; i++) {
    //   canvas.drawLine(lineStart, lineEnd, _separatorPaint);
    //   lineStart = Offset(lineStart.dx, lineStart.dy + rowHeight);
    //   lineEnd = Offset(lineEnd.dx, lineEnd.dy + rowHeight);
    // }

    canvas.restore();
  }
}
