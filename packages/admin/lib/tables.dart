import 'package:flutter/material.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

const cellDimension = CellDimensions(
  contentCellWidth: 200.0,
  contentCellHeight: 40.0,
  stickyLegendWidth: 180.0,
  stickyLegendHeight: 40.0,
);

class DataTableView extends StatelessWidget {
  final dynamic data;
  final List<String> headers;
  final Map<String, Function() Function(dynamic)> callbacks;
  final String title;
  final bool Function(dynamic) filter;
  const DataTableView(
    this.title,
    this.data,
    this.headers,
    this.callbacks, {
    this.filter,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var columnTitles = headers
        .map<StickyTableCell>((e) => StickyTableCell.stickyRow(e))
        .toList();
    var rowTitles = <Widget>[];
    var cells = <List<Widget>>[];

    data
        .where((filter == null) ? (dynamic _) => true : filter)
        .forEach((dynamic row) {
      // turn into callback
      rowTitles.add(
          StickyTableCell.stickyColumn('${row["ownerId"]}: ${row["name"]}'));
      var _cells = <Widget>[];
      headers.forEach((String header) {
        String cellContents;
        if (row[header] == null) {
          cellContents = '';
        } else if (row[header] is int) {
          cellContents = (row[header] as int).toString();
        } else if (row[header] is double) {
          cellContents = (row[header] as double).toString();
        } else if (row[header] is String) {
          cellContents = (row[header]).toString();
        }

        if (callbacks.containsKey(header)) {
          _cells.add(StickyTableCell.content(
            cellContents,
            onTap: callbacks[header](row),
          ));
        }

        _cells.add(StickyTableCell.content(cellContents));
      });
      cells.add(_cells);
    });

    return Container(
      decoration: const BoxDecoration(color: Colors.blue),
      child: StickyHeadersTable(
        columnsLength: columnTitles.length,
        rowsLength: rowTitles.length,
        columnsTitleBuilder: (i) => columnTitles[i],
        rowsTitleBuilder: (i) => rowTitles[i],
        contentCellBuilder: (i, j) => cells[j][i],
        legendCell: StickyTableCell.legend(title),
        cellFit: BoxFit.none,
        cellDimensions: cellDimension,
      ),
    );
  }
}

class StickyTableCell extends StatelessWidget {
  StickyTableCell.content(
    this.text, {
    this.textStyle,
    this.cellDimensions = cellDimension,
    this.colorBg = Colors.white,
    this.onTap,
  })  : cellWidth = cellDimensions.contentCellWidth,
        cellHeight = cellDimensions.contentCellHeight,
        _colorHorizontalBorder = Colors.amber,
        _colorVerticalBorder = Colors.amber,
        _textAlign = TextAlign.center,
        _padding = EdgeInsets.zero;

  StickyTableCell.legend(
    this.text, {
    this.textStyle,
    this.cellDimensions = cellDimension,
    this.colorBg = Colors.amber,
    this.onTap,
  })  : cellWidth = cellDimensions.stickyLegendWidth,
        cellHeight = cellDimensions.stickyLegendHeight,
        _colorHorizontalBorder = Colors.white,
        _colorVerticalBorder = Colors.white,
        _textAlign = TextAlign.start,
        _padding = const EdgeInsets.only(left: 24.0);

  StickyTableCell.stickyRow(
    this.text, {
    this.textStyle,
    this.cellDimensions = cellDimension,
    this.colorBg = Colors.amber,
    this.onTap,
  })  : cellWidth = cellDimensions.contentCellWidth,
        cellHeight = cellDimensions.stickyLegendHeight,
        _colorHorizontalBorder = Colors.white,
        _colorVerticalBorder = Colors.amber,
        _textAlign = TextAlign.center,
        _padding = EdgeInsets.zero;

  StickyTableCell.stickyColumn(
    this.text, {
    this.textStyle,
    this.cellDimensions = cellDimension,
    this.colorBg = Colors.amber,
    this.onTap,
  })  : cellWidth = cellDimensions.stickyLegendWidth,
        cellHeight = cellDimensions.contentCellHeight,
        _colorHorizontalBorder = Colors.amber,
        _colorVerticalBorder = Colors.white,
        _textAlign = TextAlign.start,
        _padding = EdgeInsets.only(left: 24.0);

  final CellDimensions cellDimensions;

  final String text;
  final Function() onTap;

  final double cellWidth;
  final double cellHeight;

  final Color colorBg;
  final Color _colorHorizontalBorder;
  final Color _colorVerticalBorder;

  final TextAlign _textAlign;
  final EdgeInsets _padding;

  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cellWidth,
        height: cellHeight,
        padding: _padding,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: Text(
                  text,
                  style: textStyle,
                  maxLines: 2,
                  textAlign: _textAlign,
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 1.1,
              color: _colorVerticalBorder,
            ),
          ],
        ),
        decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: _colorHorizontalBorder),
              right: BorderSide(color: _colorHorizontalBorder),
            ),
            color: colorBg),
      ),
    );
  }
}
