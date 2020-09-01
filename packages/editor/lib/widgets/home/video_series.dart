import 'dart:math';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter/services.dart';

enum ContentType {
  video, blog
}

class VideoSeriesContainer extends StatefulWidget {

  const VideoSeriesContainer({
    @required this.title,
    Key key, 
    this.tag,
    this.blurb,
    this.riveFile,
    this.animationName = 'Untitled 1',
    this.episodes,
    this.fillColor = const Color(0x00000000)
  }) : super(key: key);

  final String tag;
  final String title;
  final String blurb;
  final String riveFile;
  final String animationName;
  final Color fillColor;
  final List<VideoSeriesEpisode> episodes;

  @override
  _VideoSeriesContainerState createState() => _VideoSeriesContainerState();
}

class _VideoSeriesContainerState extends State<VideoSeriesContainer> {

  Artboard _riveArtboard;
  final _railKey = GlobalKey();
  bool _displayPageForward = true;
  bool _displayPageBackward = false;
  RiveAnimationController _riveController;
  final ScrollController _scrollController = ScrollController();
  final double _episodeWidth = 226.0;
  final double _containerHeight = 540.0;

  @override
  void initState() {
    super.initState();
    rootBundle.load('assets/animations/${widget.riveFile}').then(
      (data) async {
        var file = RiveFile();
        var success = file.import(data);
        if (success) {
          var artboard = file.mainArtboard;
          artboard.addController(
            _riveController = SimpleAnimation(widget.animationName)
          );
          setState(() => _riveArtboard = artboard);
        }
      },
    );
  }

  double get _scrollExtent {
    return _episodeWidth * widget.episodes.length;
  }

  void _paginate({ bool reverse }) {
    double destination = reverse 
    ? max(
      _scrollController.position.pixels - _episodeWidth * 2, 
      _scrollController.position.minScrollExtent)
    : min(
      _scrollController.position.pixels + _episodeWidth * 2, 
      _scrollController.position.maxScrollExtent);

    _scrollController.animateTo(
      destination,
      duration: const Duration(milliseconds: 250), 
      curve: Curves.ease);
  }

  /// Episodes rail that sits within the series container.
  Widget get _episodeRail {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final pix = notification.metrics.pixels;
          final min = notification.metrics.minScrollExtent;
          final max = notification.metrics.maxScrollExtent;
          setState(() {
            _displayPageBackward = pix > min;
            _displayPageForward = pix < max;
          });
        }
        return true;
      },
      child: SingleChildScrollView(
        key: _railKey,
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Container(
          height: 196,
          padding: const EdgeInsets.symmetric(
              horizontal: 30),
          child: Container(
            margin: const EdgeInsets.only(bottom: 30),
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: Offset(0, 4))
                ]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(children: widget.episodes)),
          ),
        )
      ),
    );
  }

  /// Horizontal inner shadows for the episode rail.
  Widget _railShadow(bool display, { bool reverse = false }) {
    return Positioned(
      left: reverse ? 0 : null,
      right: reverse ? null : 0, 
      bottom: 30,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: display ? 1.0 : 0.0,
        child: Container(
          height: 166,
          width: 15,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.topRight,
              colors: [
                widget.fillColor.withOpacity(
                  reverse ? 0.8 : 0.0),
                widget.fillColor.withOpacity(
                  reverse ? 0.0 : 0.8)]
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {    
    final theme = RiveTheme.of(context);
    return LayoutBuilder(builder: (context, constraints) {
      final bool isWide = _containerHeight / constraints.minWidth < 0.5625;
      return Padding(
        padding: const EdgeInsets.only(top: 30),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: _containerHeight,
            color: widget.fillColor,
            child: Stack(children: [

              /// 1. Background animation
              _riveArtboard == null
                ? const SizedBox()
                : Rive(
                    artboard: _riveArtboard,
                    fit: isWide ? BoxFit.contain : BoxFit.cover,
                    alignment: isWide 
                      ? Alignment.centerRight : Alignment.topCenter,
                ),

              /// 2. Gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomLeft,
                    colors: [Color(0x00262626), Color(0xCC262626)],
                  ),
                )
              ),

              /// 3. Content
              Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.tag, 
                          style: theme.textStyles.videoSeriesTag),
                        const SizedBox(height: 10),
                        Text(widget.title, 
                          style: theme.textStyles.videoSeriesTitle),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: 500,
                          child: Text(widget.blurb,
                            style: theme.textStyles.videoSeriesBlurb)),
                        const SizedBox(height: 30),
                      ]
                    )
                  ),

                  /// Nested rail of episodes.
                  _episodeRail
                ]
              ),

              /// 4. Inner shadows for off-screen rail content.
              /// Right shadow.
              _railShadow(_displayPageForward 
                && _scrollExtent > constraints.maxWidth),
              /// Left shadow.
              _railShadow(_displayPageBackward,
                reverse: true),

              /// 5. Pagination arrow buttons.
              Positioned(
                left: 30, right: 30, bottom: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    PaginateButton(
                      reverse: true,
                      onTap: () => _paginate(reverse: true),
                      visible: _displayPageBackward),
                    const Spacer(),
                    PaginateButton(
                      onTap: _paginate,
                      visible: _displayPageForward
                        && _scrollExtent > constraints.maxWidth)
                ]),
              )],
            ),
          ),
        ),
      );
    });
  }
}

class PaginateButton extends StatelessWidget {

  const PaginateButton({
    Key key, 
    this.onTap,
    this.reverse,
    this.visible = true
  }) : super(key: key);
  
  final Function() onTap;
  final bool reverse;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Visibility(
      visible: visible,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 4))
              ]),
          child: Center(
            child: Transform.rotate(
              angle: reverse ? 0 : pi,
              child: TintedIcon(
                color: theme.colors.fileIconColor,
                icon: PackedIcon.back,
              ),
            ),
          ))),
    );
  }
}

class VideoSeriesEpisode extends StatefulWidget {

  const VideoSeriesEpisode({
    Key key, 
    this.episodeNumber, 
    this.title, 
    this.thumbnail, 
    this.url,
    this.type = ContentType.video,
    this.hasWatched = false,
  }) : super(key: key);

  final int episodeNumber;
  final String title;
  final String thumbnail;
  final String url;
  final ContentType type;
  final bool hasWatched;

  @override
  _VideoSeriesEpisodeState createState() => _VideoSeriesEpisodeState();
}

class _VideoSeriesEpisodeState extends State<VideoSeriesEpisode> {

  bool _isHovered = false;
  final _thumnailDir = 'https://cdn.rive.app/get-started/thumbnails/';

  void _setHover(bool value) {
    if (_isHovered == value || widget.url == null) {
      return;
    }

    setState(()  => _isHovered = value);
  }

  List<Widget> get _comingSoon {
    final theme = RiveTheme.of(context);
    return [
      Container(color: const Color(0x80000000)),
      Positioned(
        top: 8, right: 8,
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(
            horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colors.getTransparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              width: 1.0,
              color: theme.colors.panelBackgroundLightGrey
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                spreadRadius: 0,
                blurRadius: 2,
                offset: Offset(0, 2))
              ]
            ),
        child: Text('Coming soon', 
          style: TextStyle(
            fontFamily: 'Roboto-Regular',
            color: theme.colors.panelBackgroundLightGrey,
            fontSize: 11,
            fontWeight: FontWeight.w300,
          ))
        )
      )
    ];
  }

  Iterable<PackedIcon> get _icon {
    switch (widget.type) {
      case ContentType.blog:
        return PackedIcon.helpCenter;
      default:
        return PackedIcon.play;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: widget.url != null
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () async {
          if (await canLaunch(widget.url)) {
            await launch(widget.url);
          }
        },
        child: SizedBox(
          width: widget.episodeNumber == 1 ? 224 : 226,
          child: Container(
            margin: EdgeInsets.only(
              left: widget.episodeNumber == 1 ? 0 : 2),
            color: theme.colors.toolbarBackground,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      FadeInImage.assetNetwork(
                        placeholder: 'assets/images/placeholder.png',
                        image: _thumnailDir + widget.thumbnail,
                        fadeInDuration: const Duration(milliseconds: 300),
                        fit: BoxFit.cover),
                      if (widget.url == null)
                        ..._comingSoon
                    ],
                  )
                ),
                SizedBox(
                  height: 40,
                  child: Container(
                    color: _isHovered
                      ? theme.colors.textButtonLightHover
                      : theme.colors.panelBackgroundLightGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${widget.episodeNumber}. ${widget.title}',
                          style: theme.textStyles.urlBlurb),
                        if (_isHovered)
                          TintedIcon(
                            color: theme.colors.treeIconHovered,
                            icon: _icon),
                      ],
                    )
                  ),
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}