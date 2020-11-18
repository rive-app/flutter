import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/home/video_series.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter/services.dart';

/// Panel showing getting started assets
class GetStartedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Center(
      child: Container(
        color: theme.colors.fileBrowserBackground,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Flexible(child: MiddlePanel()),
              SizedBox(width: 360, child: RightPanel()),
            ],
          ),
        ),
      ),
    );
  }
}

class MiddlePanel extends StatelessWidget {
  const MiddlePanel();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        VideoSeriesContainer(
            tag: '01',
            title: 'Welcome to Rive!',
            blurb: 'Jump straight in and get started'
                ' with this ‘quick start’ video series.'
                ' We’ll walk you through all the basics'
                ' to get you up and running in no time.',
            riveFile: 'get_started.riv',
            fillColor: Color(0xFF0D101B),
            episodes: [
              VideoSeriesEpisode(
                  episodeNumber: 1,
                  title: 'Get started',
                  thumbnail: 's1-e1.png',
                  type: ContentType.video,
                  url:
                      'https://www.youtube.com/watch?v=5eEXkV0_zuU'),
              VideoSeriesEpisode(
                  episodeNumber: 2,
                  title: 'Interface overview',
                  thumbnail: 's1-e2.png',
                  type: ContentType.video,
                  url:
                      'https://www.youtube.com/watch?v=S-sSF09NCvs'),
              VideoSeriesEpisode(
                  episodeNumber: 3,
                  title: 'Select and navigate',
                  thumbnail: 'selection.png',
                  type: ContentType.video,
                  url: 'https://www.youtube.com/watch?v=j4LH4uq7JT4'),
              VideoSeriesEpisode(
                  episodeNumber: 4,
                  title: 'Hierarchical relationships',
                  thumbnail: 'hierarchical.png',
                  type: ContentType.video,
                  url: 'https://www.youtube.com/watch?v=uZGCbQ0ZK9M'),
              VideoSeriesEpisode(
                  episodeNumber: 5,
                  title: 'Artboards and shapes',
                  thumbnail: 's1-e3.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/editor/fundamentals/artboards'),
              VideoSeriesEpisode(
                  episodeNumber: 6,
                  title: 'Animate mode',
                  thumbnail: 's1-e4.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/editor/animate-mode'),
              VideoSeriesEpisode(
                  episodeNumber: 7,
                  title: 'Importing and exporting',
                  thumbnail: 's1-e5.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/fundamentals/importing-assets'),
            ]),
        VideoSeriesContainer(
            tag: '02',
            title: 'Distinctly Rive',
            blurb: 'If you\'re familiar with other design and animation'
                ' tools then you\'ll feel right at home with Rive. That said,'
                ' there are some aspects we approach differently,'
                ' so we created this video series to help.',
            riveFile: 'distinctly_rive.riv',
            fillColor: Color(0xFF541B4D),
            episodes: [
              VideoSeriesEpisode(
                  episodeNumber: 1,
                  title: 'Shapes and paths',
                  thumbnail: 's2-e1.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/fundamentals/shapes-and-paths'),
              VideoSeriesEpisode(
                  episodeNumber: 2,
                  title: 'The hierarchy',
                  thumbnail: 's2-e2.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/fundamentals/interface-overview/hierarchy'),
              VideoSeriesEpisode(
                  episodeNumber: 3,
                  title: 'Bones',
                  thumbnail: 's2-e3.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/manipulating-shapes/bones'),
              VideoSeriesEpisode(
                  episodeNumber: 4,
                  title: 'Editing vertices',
                  thumbnail: 's2-e4.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/manipulating-shapes/editing-vertices'),
              VideoSeriesEpisode(
                  episodeNumber: 5,
                  title: 'Time-saving shortcuts',
                  thumbnail: 's2-e5.png',
                  type: ContentType.helpCenter,
                  url:
                      'https://help.rive.app/editor/miscellaneous/keyboard-shortcuts'),
              VideoSeriesEpisode(
                  episodeNumber: 6,
                  title: 'Draw order',
                  thumbnail: 's2-e6.png'),
              VideoSeriesEpisode(
                  episodeNumber: 7,
                  title: 'Origin and freeze',
                  thumbnail: 's2-e7.png'),
              VideoSeriesEpisode(
                  episodeNumber: 8,
                  title: 'Constraints',
                  thumbnail: 's2-e8.png'),
              VideoSeriesEpisode(
                  episodeNumber: 9, title: 'Remixing!', thumbnail: 's2-e9.png'),
            ]),
        VideoSeriesContainer(
            tag: '03',
            title: 'Runtime funtime',
            blurb: 'Ready to integrate your Rive animations into your site,'
                ' app, or game? Join us in this series on implementing'
                ' and interacting with your animations!',
            riveFile: 'runtime_funtime.riv',
            fillColor: Color(0xFFDFC0D8),
            episodes: [
              VideoSeriesEpisode(
                  episodeNumber: 1,
                  title: 'Overview',
                  thumbnail: 's3-e1.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/runtimes/overview'),
              VideoSeriesEpisode(
                  episodeNumber: 2,
                  title: 'Our web runtime',
                  thumbnail: 's3-e2.png',
                  type: ContentType.blog,
                  url: 'https://blog.rive.app/rives-web-runtime/'),
              VideoSeriesEpisode(
                  episodeNumber: 3,
                  title: 'Integrating into your app',
                  thumbnail: 's3-e3.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/runtimes/add-runtime'),
              VideoSeriesEpisode(
                  episodeNumber: 4,
                  title: 'Loading a Rive file',
                  thumbnail: 's1-e5.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/runtimes/load-file'),
              VideoSeriesEpisode(
                  episodeNumber: 5,
                  title: 'Control animations',
                  thumbnail: 's3-e5.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/runtimes/play-animation'),
              VideoSeriesEpisode(
                  episodeNumber: 6,
                  title: 'Full example',
                  thumbnail: 's3-e6.png',
                  type: ContentType.helpCenter,
                  url: 'https://help.rive.app/runtimes/example'),
              VideoSeriesEpisode(
                  episodeNumber: 7,
                  title: 'Export via the API',
                  thumbnail: 's1-e5.png'),
            ]),
        SizedBox(height: 30),
      ],
    );
  }
}

class RightPanel extends StatefulWidget {
  @override
  _RightPanelState createState() => _RightPanelState();
}

class _RightPanelState extends State<RightPanel> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _hasResponded = ValueNotifier<bool>(false);
  List<Widget> _panelContent;

  @override
  void initState() {
    super.initState();
    _panelContent = [
      /// Removed until responses can be linked up to something.
      ///
      // UserQuery(
      //   respond: _hasResponded,
      //   onDismiss: _dismissQueryPanel),
      // QueryResponses(
      //   options: const [
      //     'Product designer',
      //     'Game designer',
      //     'Developer',
      //     'Other'],
      //   onSelection: _submitResponse),
      QuickLinks()
    ];
  }

  /// Called upon selection of a response.
  void _submitResponse(String response) {
    if (_hasResponded.value == true) {
      return;
    }

    int removeIndex =
        _panelContent.indexWhere((item) => item is QueryResponses);

    Widget removedItem = _panelContent.removeAt(removeIndex);

    _listKey.currentState.removeItem(
        removeIndex, (_, animation) => _buildItem(removedItem, animation),
        duration: const Duration(milliseconds: 500));

    _hasResponded.value = true;
  }

  /// Panel becomes dismissable after responding.
  void _dismissQueryPanel() {
    int removeIndex = _panelContent.indexWhere((item) => item is UserQuery);

    final removedItem = _panelContent.removeAt(removeIndex);

    _listKey.currentState.removeItem(
        removeIndex,
        (_, animation) =>
            _buildItem(removedItem, animation, axisAlignment: 1.0),
        duration: const Duration(milliseconds: 500));
  }

  Widget _buildItem(Widget item, Animation<double> animation,
      {double axisAlignment = -1.0}) {
    return SizeTransition(
        child: item,
        axis: Axis.vertical,
        axisAlignment: axisAlignment,
        sizeFactor: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInCirc)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30),
      child: AnimatedList(
          key: _listKey,
          initialItemCount: _panelContent.length,
          itemBuilder: (context, index, animation) {
            return _buildItem(_panelContent[index], animation);
          }),
    );
  }
}

/// Links in the right column

class QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            UrlCard(
                icon: PackedIcon.helpCenter,
                blurb: 'Help Center',
                url: 'https://help.rive.app'),
            SizedBox(height: 2),
            UrlCard(
                icon: PackedIcon.runtimes,
                blurb: 'Get the Runtimes',
                url: 'https://help.rive.app/runtimes/runtimes-overview'),
            SizedBox(height: 2),
            UrlCard(
                icon: PackedIcon.discord,
                blurb: 'Join us on Discord',
                url: 'https://discord.gg/FGjmaTr'),
            SizedBox(height: 2),
            UrlCard(
                icon: PackedIcon.signinTwitter,
                blurb: 'Follow us on Twitter',
                url: 'https://twitter.com/rive_app'),
            SizedBox(height: 2),
            UrlCard(
                icon: PackedIcon.feedback,
                blurb: 'Send feedback',
                url: 'https://feedback.rive.app'),
          ],
        ),
      ),
    );
  }
}

class UrlCard extends StatefulWidget {
  const UrlCard({
    @required this.icon,
    @required this.blurb,
    @required this.url,
  });
  final Iterable<PackedIcon> icon;
  final String blurb;
  final String url;

  @override
  _UrlCardState createState() => _UrlCardState();
}

class _UrlCardState extends State<UrlCard> {
  bool _isHovered = false;

  void _setHover(bool value) {
    if (_isHovered == value) {
      return;
    }

    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return MouseRegion(
      onEnter: (_) => _setHover(true),
      onExit: (_) => _setHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (await canLaunch(widget.url)) {
            await launch(widget.url);
          }
        },
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: _isHovered
                  ? theme.colors.buttonLightHover
                  : theme.colors.panelBackgroundLightGrey),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TintedIcon(color: theme.colors.fileIconColor, icon: widget.icon),
              const SizedBox(width: 15),
              Text(widget.blurb, style: theme.textStyles.urlBlurb),
              const Spacer(),
              TintedIcon(
                  color: theme.colors.fileIconColor, icon: PackedIcon.chevron)
            ],
          ),
        ),
      ),
    );
  }
}

class UserQuery extends StatefulWidget {
  const UserQuery({Key key, this.respond, this.onDismiss}) : super(key: key);

  final ValueListenable<bool> respond;
  final Function() onDismiss;

  @override
  _UserQueryState createState() => _UserQueryState();
}

class _UserQueryState extends State<UserQuery>
    with SingleTickerProviderStateMixin {
  Artboard _riveArtboard;
  Artboard _riveArtboardConfirm;
  Animation<BorderRadius> _borderRadiusAnimation;
  AnimationController _borderRadiusController;

  @override
  void initState() {
    super.initState();

    loadRiveFile('user_query.riv',
        (artboard) => setState(() => _riveArtboard = artboard));

    loadRiveFile('user_query_confirm.riv',
        (artboard) => setState(() => _riveArtboardConfirm = artboard));

    _borderRadiusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _borderRadiusAnimation = BorderRadiusTween(
            begin: const BorderRadius.vertical(top: Radius.circular(10)),
            end: BorderRadius.circular(10))
        .animate(_borderRadiusController);
  }

  void loadRiveFile(String file, Function(Artboard) onLoad) {
    rootBundle.load('assets/animations/$file').then((data) async {
      var file = RiveFile();
      var success = file.import(data);
      if (success) {
        var artboard = file.mainArtboard;
        artboard.addController(
          SimpleAnimation('Untitled 1'),
        );
        onLoad(artboard);
      }
    });
  }

  Widget get _requestState {
    final theme = RiveTheme.of(context);
    return Column(key: const ValueKey<int>(0), children: [
      SizedBox(
          height: 100,
          child: _riveArtboard == null
              ? const SizedBox()
              : Rive(
                  artboard: _riveArtboard,
                  fit: BoxFit.contain,
                  alignment: Alignment.center)),
      Text('Quick question!', style: theme.textStyles.urlBlurb),
      const SizedBox(height: 15),
      Text('What role best describes you?', style: theme.textStyles.userQuery),
      const SizedBox(height: 15),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Text(
              'Help us tailor your experience by getting'
              ' to know you and how you want to use Rive.',
              style: theme.textStyles.urlBlurb,
              textAlign: TextAlign.center)),
      const SizedBox(height: 15),
    ]);
  }

  Widget get _responseState {
    final theme = RiveTheme.of(context);
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Column(key: const ValueKey<int>(1), children: [
        SizedBox(
            height: 100,
            child: _riveArtboard == null
                ? const SizedBox()
                : Rive(
                    artboard: _riveArtboardConfirm,
                    fit: BoxFit.contain,
                    alignment: Alignment.center)),
        Text('High five!', style: theme.textStyles.urlBlurb),
        const SizedBox(height: 15),
        Text('Thanks for letting us know', style: theme.textStyles.userQuery),
        const SizedBox(height: 15),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
                'We\'ll be sure to let you know when'
                ' we add new content we think you\'ll like.',
                style: theme.textStyles.urlBlurb,
                textAlign: TextAlign.center)),
        const SizedBox(height: 15),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: AnimatedBuilder(
        animation: _borderRadiusController,
        builder: (_, child) {
          return Container(
              decoration: BoxDecoration(
                  color: theme.colors.panelBackgroundLightGrey,
                  borderRadius: _borderRadiusAnimation.value),
              child: child);
        },
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.respond,
          builder: (conext, responded, child) {
            if (responded && !_borderRadiusController.isCompleted) {
              _borderRadiusController.forward();
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 1000),
              transitionBuilder: (child, animation) {
                final opacityAnimation = TweenSequence([
                  TweenSequenceItem(tween: ConstantTween(0.0), weight: 50),
                  TweenSequenceItem(
                      tween: Tween<double>(begin: 0.0, end: 1.0), weight: 50),
                ]).animate(animation);

                return FadeTransition(opacity: opacityAnimation, child: child);
              },
              child: responded ? _responseState : _requestState,
            );
          },
        ),
      ),
    );
  }
}

class QueryResponses extends StatefulWidget {
  const QueryResponses({@required this.options, Key key, this.onSelection})
      : super(key: key);

  final List<String> options;
  final Function(String) onSelection;

  @override
  _QueryResponsesState createState() => _QueryResponsesState();
}

class _QueryResponsesState extends State<QueryResponses> {
  int _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Column(
      children: widget.options
          .asMap()
          .map((index, value) {
            return MapEntry(
                index,
                MouseRegion(
                    onEnter: (_) => setState(() => _hoverIndex = index),
                    onExit: (_) => setState(() => _hoverIndex = null),
                    child: GestureDetector(
                        onTap: () => widget.onSelection(value),
                        child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(
                                      index == widget.options.length - 1
                                          ? 10
                                          : 0)),
                              color: index == _hoverIndex
                                  ? theme.colors.buttonLightHover
                                  : theme.colors.panelBackgroundLightGrey,
                            ),
                            child: Center(
                                child: Text(value,
                                    style: theme.textStyles.urlBlurb))))));
          })
          .values
          .toList(),
    );
  }
}
