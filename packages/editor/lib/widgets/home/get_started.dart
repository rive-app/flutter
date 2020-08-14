import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:url_launcher/url_launcher.dart';

/// Panel showing getting started assets
class GetStartedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return Center(
      child: Container(
        color: theme.colors.fileBrowserBackground,
        constraints: BoxConstraints(minWidth: 800, maxWidth: 1114),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 30,
          ),
          child: Row(
            children: const <Widget>[
              Flexible(
                flex: 2,
                child: MiddlePanel(),
              ),
              Flexible(flex: 1, child: RightPanel()),
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
        SizedBox(height: 30),
        LargeCard(
          backgroundImageAsset: 'assets/images/space_man.png',
          url: 'https://f.io/39_jZ-_N',
          heading: 'Quick Start',
          blurb: 'Watch this video to learn the basics '
              'and core concepts you need to get started',
        ),
        SizedBox(height: 30),
        // LargeCard(
        //   backgroundImageAsset: 'assets/images/mother_of_dashes.png',
        //   url: 'https://www.youtube.com/watch?v=oHg5SJYRHA0',
        //   heading: 'More Getting Started',
        //   blurb: 'More getting started to go here',
        // ),
        // SizedBox(height: 30),
      ],
    );
  }
}

class RightPanel extends StatelessWidget {
  const RightPanel();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 30, top: 30),
      child: Column(
        children: const [
          // UrlCard(
          //   icon: PackedIcon.desktop,
          //   blurb: 'Get the desktop app!',
          //   url: 'https://rive.app/',
          // ),
          // SizedBox(height: 20),
          UrlCard(
            icon: PackedIcon.helpCenter,
            blurb: 'Help Center',
            url: 'https://help.rive.app',
          ),
          SizedBox(height: 20),
          UrlCard(
            icon: PackedIcon.runtimes,
            blurb: 'Get the Runtimes',
            url: 'https://github.com/rive-app/rive-flutter',
          ),
          SizedBox(height: 20),
          UrlCard(
            icon: PackedIcon.discord,
            blurb: 'Join us on Discord',
            url: 'https://discord.gg/FGjmaTr',
          ),
          SizedBox(height: 20),
          UrlCard(
            icon: PackedIcon.signinTwitter,
            blurb: 'Follow us on Twitter',
            url: 'https://twitter.com/rive_app',
          ),
          SizedBox(height: 20),
          UrlCard(
            icon: PackedIcon.feedback,
            blurb: 'Send feedback',
            url: 'https://feedback.rive.app',
          ),
        ],
      ),
    );
  }
}

/// Large image cards in the middle column
class LargeCard extends StatelessWidget {
  const LargeCard(
      {@required this.backgroundImageAsset,
      @required this.url,
      this.heading,
      this.blurb,
      Key key})
      : super(key: key);
  final String backgroundImageAsset;
  final String url;
  final String heading;
  final String blurb;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        }
      },
      child: Stack(
        children: [
          Container(
            // width: 685,
            height: 384,
            decoration: BoxDecoration(
                image: DecorationImage(
                image: AssetImage(backgroundImageAsset),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            child: Container(
              //add gradient overlay to image so text is more legible
              height: 384,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                begin: Alignment(0.0, 0.3),
                end: Alignment.bottomCenter,
                colors: [const Color(0x00000000), const Color(0x59000000)],
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Row(
              children: [
                const PlayIcon(),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: theme.textStyles.cardHeading,
                    ),
                    SizedBox(
                      width: 300,
                      child: Text(
                        blurb,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: theme.textStyles.cardBlurb,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Links in the right column
class UrlCard extends StatelessWidget {
  const UrlCard({
    @required this.icon,
    @required this.blurb,
    @required this.url,
  });
  final Iterable<PackedIcon> icon;
  final String blurb;
  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return GestureDetector(
      onTap: () async {
        if (await canLaunch(url)) {
          await launch(url);
        }
      },
      child: Container(
        //width: 200,
        decoration: BoxDecoration(
          color: theme.colors.panelBackgroundLightGrey,
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TintedIcon(color: theme.colors.fileIconColor, icon: icon),
              const SizedBox(width: 10),
              Text(blurb, style: theme.textStyles.urlBlurb),
              const Spacer(),
              TintedIcon(
                color: theme.colors.fileIconColor,
                icon: PackedIcon.chevron,
              )
            ],
          ),
        ),
      ),
    );
  }
}

/// Play icon indicating video playback
@immutable
class PlayIcon extends LeafRenderObjectWidget {
  const PlayIcon();
  @override
  RenderObject createRenderObject(BuildContext context) {
    return PlayIconRenderBox();
  }
}

class PlayIconRenderBox extends RenderBox {
  final _circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFFFFF);

  final _trianglePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFFFFFF);

  @override
  void performLayout() {
    size = const Size(40, 40);
  }

  @override
  bool get sizedByParent => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    // Draw the circle
    canvas.drawCircle(offset.translate(20, 20), 20, _circlePaint);
    // Draw the arrow
    final x = offset.dx + 20 - 7.5;
    final y = offset.dy + 20 - 10;
    canvas.translate(x, y);
    final trianglePath = Path()
      ..lineTo(0, 20)
      ..lineTo(20, 10)
      ..close();
    canvas.drawPath(trianglePath, _trianglePaint);
    canvas.translate(-x, -y);
  }
}
