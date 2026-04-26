import 'package:flutter/material.dart';
import 'package:shared/constants/eco_palette.dart';
import 'package:shared/constants/editorial_typography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wonwon_client/localization/app_localizations_wrapper.dart';

/// Three-screen onboarding carousel shown on first launch. Frames the
/// repair act as a quiet, meaningful choice — not a cheap pitch.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({Key? key, required this.onComplete})
      : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  static const String _seenKey = 'onboarding_v1_seen';

  /// Has the user already completed onboarding?
  static Future<bool> hasBeenSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Mark onboarding as complete so it never shows again.
  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, true);
    } catch (_) {}
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnbPageContent(
      eyebrowKey: 'onb_1_eyebrow',
      titleKey: 'onb_1_title',
      bodyKey: 'onb_1_body',
      illustration: _OnbIllustration.landfill,
    ),
    _OnbPageContent(
      eyebrowKey: 'onb_2_eyebrow',
      titleKey: 'onb_2_title',
      bodyKey: 'onb_2_body',
      illustration: _OnbIllustration.hands,
    ),
    _OnbPageContent(
      eyebrowKey: 'onb_3_eyebrow',
      titleKey: 'onb_3_title',
      bodyKey: 'onb_3_body',
      illustration: _OnbIllustration.leaf,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoPalette.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _complete,
                  style: TextButton.styleFrom(
                    foregroundColor: EcoPalette.inkMuted,
                  ),
                  child: Text(
                    'onb_skip'.tr(context),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _OnbPage(content: _pages[i]),
              ),
            ),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? EcoPalette.leaf
                        : EcoPalette.hairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EcoPalette.leaf,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1
                        ? 'onb_next'.tr(context)
                        : 'onb_start'.tr(context),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

enum _OnbIllustration { landfill, hands, leaf }

class _OnbPageContent {
  final String eyebrowKey;
  final String titleKey;
  final String bodyKey;
  final _OnbIllustration illustration;

  const _OnbPageContent({
    required this.eyebrowKey,
    required this.titleKey,
    required this.bodyKey,
    required this.illustration,
  });
}

class _OnbPage extends StatelessWidget {
  final _OnbPageContent content;
  const _OnbPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 160,
            width: 160,
            child: _OnbArtwork(illustration: content.illustration),
          ),
          const SizedBox(height: 48),
          Text(
            content.eyebrowKey.tr(context),
            style: EditorialTypography.eyebrowLeaf,
          ),
          const SizedBox(height: 14),
          Text(
            content.titleKey.tr(context),
            textAlign: TextAlign.center,
            style: EditorialTypography.displayLarge,
          ),
          const SizedBox(height: 14),
          Text(
            content.bodyKey.tr(context),
            textAlign: TextAlign.center,
            style: EditorialTypography.body,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _OnbArtwork extends StatelessWidget {
  final _OnbIllustration illustration;
  const _OnbArtwork({required this.illustration});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EcoPalette.leafWash,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(84, 84),
          painter: _OnbPainter(illustration: illustration),
        ),
      ),
    );
  }
}

class _OnbPainter extends CustomPainter {
  final _OnbIllustration illustration;
  _OnbPainter({required this.illustration});

  @override
  void paint(Canvas canvas, Size size) {
    switch (illustration) {
      case _OnbIllustration.landfill:
        _paintLandfill(canvas, size);
        break;
      case _OnbIllustration.hands:
        _paintHands(canvas, size);
        break;
      case _OnbIllustration.leaf:
        _paintLeaf(canvas, size);
        break;
    }
  }

  void _paintLandfill(Canvas canvas, Size size) {
    final line = Paint()
      ..color = EcoPalette.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // Stacked boxes forming a pile
    final rects = [
      Rect.fromLTWH(size.width * 0.12, size.height * 0.55, size.width * 0.3,
          size.height * 0.28),
      Rect.fromLTWH(size.width * 0.42, size.height * 0.45, size.width * 0.28,
          size.height * 0.38),
      Rect.fromLTWH(size.width * 0.22, size.height * 0.30, size.width * 0.25,
          size.height * 0.25),
      Rect.fromLTWH(size.width * 0.5, size.height * 0.18, size.width * 0.22,
          size.height * 0.2),
    ];
    for (final r in rects) {
      canvas.drawRect(r, line);
    }
    // Ground line
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.9),
      Offset(size.width * 0.95, size.height * 0.9),
      line,
    );
  }

  void _paintHands(Canvas canvas, Size size) {
    final line = Paint()
      ..color = EcoPalette.leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Two cupped curves forming hands meeting at center
    final left = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.15, size.height * 0.85,
          size.width * 0.5, size.height * 0.75);
    final right = Path()
      ..moveTo(size.width * 0.9, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.85,
          size.width * 0.5, size.height * 0.75);
    canvas.drawPath(left, line);
    canvas.drawPath(right, line);

    // Small circle (the thing being held)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.12,
      line,
    );
  }

  void _paintLeaf(Canvas canvas, Size size) {
    final fill = Paint()..color = EcoPalette.leaf;
    final path = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.3,
          size.width * 0.9, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.95,
          size.width * 0.1, size.height * 0.75)
      ..quadraticBezierTo(
          size.width * 0.05, size.height * 0.3, size.width * 0.5, size.height * 0.1)
      ..close();
    canvas.drawPath(path, fill);
    final vein = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.88),
      vein,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
