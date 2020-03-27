import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

class RiveRadio<T> extends StatefulWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final Color selectedColor;
  final Color backgroundColor;
  final Color hoverColor;

  const RiveRadio({
    @required this.value,
    @required this.groupValue,
    @required this.onChanged,
    this.selectedColor,
    this.backgroundColor,
    this.hoverColor,
    Key key,
  }) : super(key: key);

  @override
  State<RiveRadio> createState() => _RiveRadioState<T>();
}

class _RiveRadioState<T> extends State<RiveRadio<T>> {
  final _focusNode = FocusNode(canRequestFocus: true, skipTraversal: true);
  bool _isHovered = false;
  bool _hasFocus = false; // TODO:

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusChange);
    super.dispose();
  }

  void _focusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _isHovered
        ? widget.hoverColor ??
            Color.lerp(const Color(0xFFF1F1F1), const Color(0xFF333333), 0.15)
        : widget.backgroundColor ?? const Color(0xFFF1F1F1);
    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (event) => setState(() {
          _isHovered = true;
        }),
        onExit: (event) => setState(() {
          _isHovered = false;
        }),
        child: _RiveRadioRenderer(
          isSelected: widget.value == widget.groupValue,
          isFocused: _hasFocus,
          selectedColor: widget.selectedColor ?? const Color(0xFF333333),
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

class _RiveRadioRenderer extends LeafRenderObjectWidget {
  final bool isSelected;
  final bool isFocused;
  final Color selectedColor;
  final Color backgroundColor;

  const _RiveRadioRenderer(
      {@required this.isSelected,
      @required this.isFocused,
      @required this.selectedColor,
      @required this.backgroundColor,
      Key key})
      : assert(isSelected != null),
        assert(selectedColor != null),
        super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => _RiveRadioRenderBox(
      isSelected: isSelected,
      selectedColor: selectedColor,
      backgroundColor: backgroundColor);
  @override
  void updateRenderObject(
      BuildContext context, _RiveRadioRenderBox renderObject) {
    renderObject
      ..isSelected = isSelected
      ..selectedColor = selectedColor
      ..backgroundColor = backgroundColor;
  }
}

class _RiveRadioRenderBox extends RenderBox {
  static const _radius = 10.0;
  static const _innerRadius = 4.0;
  static const _diameter = _radius * 2;
  _RiveRadioRenderBox(
      {@required bool isSelected,
      @required Color selectedColor,
      @required Color backgroundColor,
      ValueChanged<bool> onChanged})
      : _isSelected = isSelected,
        _onChanged = onChanged,
        _selectedColor = selectedColor,
        _backgroundColor = backgroundColor;

  bool _isSelected;
  Color _selectedColor;
  Color _backgroundColor;
  final ValueChanged<bool> _onChanged;

  bool get isSelected => _isSelected;
  set isSelected(bool value) {
    if (_isSelected == value) {
      return;
    }
    _isSelected = value;
    markNeedsPaint();
  }

  Color get selectedColor => _selectedColor;
  set selectedColor(Color value) {
    if (_selectedColor == value) {
      return;
    }
    _selectedColor = value;
    markNeedsPaint();
  }

  Color get backgroundColor => _backgroundColor;
  set backgroundColor(Color value) {
    if (_backgroundColor == value) {
      return;
    }
    _backgroundColor = value;
    markNeedsPaint();
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void performLayout() {
    size = const Size(_diameter, _diameter);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = _backgroundColor;

    final center = (offset & size).center;

    // Background circle.
    canvas.drawCircle(center, _radius, paint);

    if (_isSelected) {
      canvas.drawCircle(center, _innerRadius, paint..color = _selectedColor);
    }
  }

  void _onPressed() {
    if (_onChanged == null) return;
    if (isSelected) {
      _onChanged(true);
    } else {
      _onChanged(false);
    }
    sendSemanticsEvent(const TapSemanticEvent());
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_onChanged != null) {
      config.onTap = _onPressed;
    }
  }
}
