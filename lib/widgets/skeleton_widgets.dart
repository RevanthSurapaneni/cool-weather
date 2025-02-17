import 'package:flutter/material.dart';

class ShimmerEffect extends StatefulWidget {
  final Widget child;
  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade600,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade400,
                      Colors.grey.shade200,
                      Colors.grey.shade400,
                    ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: Matrix4Transform(_controller.value),
            ).createShader(bounds);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(child is Container ? 12 : 4),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class Matrix4Transform extends GradientTransform {
  Matrix4Transform(this.value);
  final double value;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * value, 0.0, 0.0);
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isCircle;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius:
              !isCircle ? (borderRadius ?? BorderRadius.circular(4)) : null,
        ),
      ),
    );
  }
}

class CurrentWeatherSkeleton extends StatelessWidget {
  const CurrentWeatherSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 4 : 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: isDark
                ? [
                    Colors.grey.shade900,
                    Colors.grey.shade800,
                  ]
                : [
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Updated time and sun icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 120, height: 24),
                const SkeletonBox(width: 24, height: 24, isCircle: true),
              ],
            ),
            const SizedBox(height: 24),
            // Location
            const Center(
              child: SkeletonBox(width: 200, height: 32),
            ),
            const SizedBox(height: 32),
            // Current weather
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SkeletonBox(width: 70, height: 70, isCircle: true),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 48),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 24),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Weather details grid
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: List.generate(
                7, // Changed from 8 to 7 boxes
                (_) => Container(
                  width: 120,
                  height: 110,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    // Replace gradient with solid color
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    // Remove the blue border
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SkeletonBox(width: 28, height: 28, isCircle: true),
                      SkeletonBox(width: 60, height: 14),
                      SkeletonBox(width: 40, height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForecastSkeleton extends StatelessWidget {
  const ForecastSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 24,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, __) => Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SkeletonBox(width: 40, height: 16),
                SkeletonBox(width: 40, height: 40, isCircle: true),
                SkeletonBox(width: 60, height: 12),
                SkeletonBox(width: 30, height: 12),
                SkeletonBox(width: 50, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AirQualitySkeletonWidget extends StatelessWidget {
  const AirQualitySkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonBox(width: 24, height: 24, isCircle: true),
                const SizedBox(width: 8),
                const SkeletonBox(width: 100, height: 28),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 120, height: 32), // AQI category
                    SizedBox(height: 4),
                    SkeletonBox(width: 80, height: 24), // AQI value
                  ],
                ),
                const SkeletonBox(width: 48, height: 48, isCircle: true),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonBox(width: 240, height: 20), // Description
            const SizedBox(height: 8),
            const SkeletonBox(width: 200, height: 16), // Main advice
            const SizedBox(height: 16),
            const SkeletonBox(
                width: 120, height: 20), // Sensitive Groups header
            const SizedBox(height: 8),
            Row(
              children: const [
                SizedBox(width: 16),
                SkeletonBox(width: 160, height: 16),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: const [
                SizedBox(width: 16),
                SkeletonBox(width: 140, height: 16),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: List.generate(
                6,
                (_) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      SkeletonBox(width: 40, height: 12),
                      SizedBox(height: 4),
                      SkeletonBox(width: 60, height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
