import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// Panel showing getting started assets
class GetStartedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return Container(
      color: theme.colors.panelBackgroundLightGrey,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        child: Column(
          children: const <Widget>[
            Expanded(
              child: Center(
                child: MiddlePanel(),
              ),
            ),
          ],
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
          url: 'https://www.youtube.com/watch?v=oHg5SJYRHA0',
          heading: 'Quick Start',
          blurb: 'Watch this video to learn the basics '
              'and core concepts you need to get started',
        ),
        SizedBox(height: 30),
        LargeCard(
          backgroundImageAsset: 'assets/images/mother_of_dashes.png',
          url: 'https://www.youtube.com/watch?v=oHg5SJYRHA0',
          heading: 'More Getting Started',
          blurb: 'More getting started to go here',
        ),
        SizedBox(height: 30),
      ],
    );
  }
}

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
            width: 685,
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
    ..strokeWidth = 5
    ..color = const Color(0xFFFFFFFF);

  final _trianglePaint = Paint()
    ..style = PaintingStyle.fill
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
