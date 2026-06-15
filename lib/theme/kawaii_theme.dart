import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central kawaii palette + reusable text/visual helpers.
///
/// Keeping every colour and the ghost-rendering trick in one place means the
/// whole UI stays perfectly consistent and the "black background" sprite
/// problem is solved in exactly one spot ([GhostImage]).
class KawaiiColors {
  KawaiiColors._();

  // Backgrounds
  static const Color bgDark = Color(0xFF1A0A2E); // deep purple
  static const Color bgDark2 = Color(0xFF2D1053); // home gradient end
  static const Color winEnd = Color(0xFF3D0066); // win gradient end
  static const Color loseEnd = Color(0xFF2D0030); // lose gradient end

  // Core kawaii palette
  static const Color primaryPink = Color(0xFFFF6EB4);
  static const Color softLavender = Color(0xFFC9B1FF);
  static const Color mintAccent = Color(0xFFA8FFDA);
  static const Color warmWhite = Color(0xFFFFF5F9);
  static const Color ghostWhite = Color(0xFFF0EEFF);

  // Box colours
  static const Color boxGlow = Color(0xFFFFE066); // top face / glow
  static const Color boxLeft = Color(0xFFFFB347); // left face
  static const Color boxRight = Color(0xFFE8860A); // right face

  // Outline / drop shadow
  static const Color outline = Color(0xFF3D0066);
}

/// Soft kawaii drop shadow used on most text.
List<Shadow> kawaiiTextShadow({
  Color color = KawaiiColors.outline,
  double blur = 6,
  Offset offset = const Offset(0, 3),
}) =>
    [Shadow(color: color, blurRadius: blur, offset: offset)];

/// Title text style (Pacifico) with a soft outline-coloured shadow.
TextStyle kawaiiTitle({
  double fontSize = 48,
  Color color = KawaiiColors.boxGlow,
  Color shadowColor = KawaiiColors.primaryPink,
  FontWeight fontWeight = FontWeight.normal,
}) =>
    GoogleFonts.pacifico(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      shadows: [
        Shadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 3)),
        Shadow(
            color: KawaiiColors.outline,
            blurRadius: 2,
            offset: const Offset(0, 1)),
      ],
    );

/// Body / HUD text style (Nunito) with a soft shadow.
TextStyle kawaiiBody({
  double fontSize = 16,
  Color color = KawaiiColors.warmWhite,
  FontWeight fontWeight = FontWeight.w600,
  FontStyle fontStyle = FontStyle.normal,
  Color shadowColor = KawaiiColors.outline,
}) =>
    GoogleFonts.nunito(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      shadows: kawaiiTextShadow(color: shadowColor, blur: 4),
    );

/// Composites its [child] onto whatever is painted behind it using a custom
/// [blendMode]. We use this to make the cute_ghost.png sprite's hard BLACK
/// background disappear: with [BlendMode.screen], black pixels (value 0)
/// leave the backdrop untouched while the bright ghost stays visible — over a
/// dark purple gradient OR over the live camera feed.
class BlendMask extends SingleChildRenderObjectWidget {
  final BlendMode blendMode;
  final double opacity;

  const BlendMask({
    super.key,
    this.blendMode = BlendMode.screen,
    this.opacity = 1.0,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderBlendMask(blendMode, opacity);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderBlendMask)
      ..blendMode = blendMode
      ..opacity = opacity;
  }
}

class _RenderBlendMask extends RenderProxyBox {
  BlendMode _blendMode;
  double _opacity;

  _RenderBlendMask(this._blendMode, this._opacity);

  set blendMode(BlendMode value) {
    if (value == _blendMode) return;
    _blendMode = value;
    markNeedsPaint();
  }

  set opacity(double value) {
    if (value == _opacity) return;
    _opacity = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty || child == null) return;
    // saveLayer with a blendMode composites the entire child layer onto the
    // backdrop using that mode (instead of the default srcOver).
    final paint = Paint()
      ..blendMode = _blendMode
      ..color = Color.fromRGBO(255, 255, 255, _opacity.clamp(0.0, 1.0));
    context.canvas.saveLayer(offset & size, paint);
    super.paint(context, offset);
    context.canvas.restore();
  }
}

/// The cute ghost sprite, with its black background blended away.
///
/// [tint] (optional) recolours the sprite via a `modulate` colour filter —
/// black stays black (so it still blends away) while the bright body picks up
/// the tint. Used for the brief pink flash when Boo is tapped.
class GhostImage extends StatelessWidget {
  final double size;
  final double opacity;
  final Color? tint;
  final BlendMode blendMode;

  const GhostImage({
    super.key,
    this.size = 100,
    this.opacity = 1.0,
    this.tint,
    this.blendMode = BlendMode.screen,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      'assets/img/cute_ghost.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );

    if (tint != null) {
      // modulate = multiply: pink * white body => pink, pink * black bg => black
      img = ColorFiltered(
        colorFilter: ColorFilter.mode(tint!, BlendMode.modulate),
        child: img,
      );
    }

    return BlendMask(blendMode: blendMode, opacity: opacity, child: img);
  }
}

/// Rounded gradient "pill" button (pink -> lavender) with white Pacifico text.
/// Used for START / PLAY AGAIN. When [pulse] is true it gently breathes.
class KawaiiPillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool pulse;
  final List<Color> gradient;
  final double? width;
  final double fontSize;

  const KawaiiPillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.pulse = false,
    this.gradient = const [KawaiiColors.primaryPink, KawaiiColors.softLavender],
    this.width,
    this.fontSize = 26,
  });

  @override
  State<KawaiiPillButton> createState() => _KawaiiPillButtonState();
}

class _KawaiiPillButtonState extends State<KawaiiPillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.06)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    if (widget.pulse) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: KawaiiColors.primaryPink.withValues(alpha: 0.5),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: kawaiiTitle(
            fontSize: widget.fontSize,
            color: KawaiiColors.warmWhite,
            shadowColor: KawaiiColors.outline,
          ),
        ),
      ),
    );
    if (widget.pulse) {
      button = ScaleTransition(scale: _scale, child: button);
    }
    return button;
  }
}

/// Outlined lavender pill button used for HOME.
class KawaiiOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;

  const KawaiiOutlinedButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 38, vertical: 13),
        decoration: BoxDecoration(
          color: KawaiiColors.softLavender.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: KawaiiColors.softLavender, width: 2.5),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: kawaiiTitle(
            fontSize: fontSize,
            color: KawaiiColors.softLavender,
            shadowColor: KawaiiColors.outline,
          ),
        ),
      ),
    );
  }
}
