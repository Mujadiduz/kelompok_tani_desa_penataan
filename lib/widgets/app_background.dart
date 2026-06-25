import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  final bool showPattern;
  final EdgeInsetsGeometry padding;

  const AppBackground({
    super.key,
    required this.child,
    this.showPattern = true,
    this.padding = EdgeInsets.zero,
  });

  static const Color primaryGreen = Color(0xff2E7D32);
  static const Color bgTop = Color(0xffF9FCF9);
  static const Color bgMiddle = Color(0xffF4F7F4);
  static const Color bgBottom = Color(0xffEEF7EF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bgTop, bgMiddle, bgBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -90,
            child: _circle(260, primaryGreen.withValues(alpha: 0.055)),
          ),
          Positioned(
            bottom: -95,
            left: -75,
            child: _circle(230, primaryGreen.withValues(alpha: 0.050)),
          ),
          Positioned(
            top: 210,
            left: -45,
            child: _circle(115, primaryGreen.withValues(alpha: 0.035)),
          ),
          if (showPattern) ...[
            Positioned(
              top: 86,
              right: 28,
              child: _watermark(Icons.eco_rounded, 70),
            ),
            Positioned(
              bottom: 150,
              left: 24,
              child: _watermark(Icons.grass_rounded, 58),
            ),
            Positioned(
              bottom: 54,
              right: 34,
              child: _watermark(Icons.agriculture_rounded, 68),
            ),
          ],
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _watermark(IconData icon, double size) {
    return Icon(icon, size: size, color: primaryGreen.withValues(alpha: 0.030));
  }
}
