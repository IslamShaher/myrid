import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/my_icons.dart';

class SearchingForRideAnimation extends StatefulWidget {
  const SearchingForRideAnimation({super.key});

  @override
  State<SearchingForRideAnimation> createState() => _SearchingForRideAnimationState();
}

class _SearchingForRideAnimationState extends State<SearchingForRideAnimation> with TickerProviderStateMixin {
  late AnimationController _roadController;
  late AnimationController _carController;
  late Animation<double> _roadAnimation;
  late Animation<double> _carAnimation;

  final double carSize = 50.0;
  final double lineHeight = 6.0;
  final double roadSegmentWidth = 100.0;

  @override
  void initState() {
    super.initState();

    _roadController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _carController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _roadAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _roadController, curve: Curves.linear),
    );

    // Option 1: Use a smooth curve that naturally loops
    _carAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _carController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _roadController.dispose();
    _carController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: fullWidth,
      height: carSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_roadAnimation, _carAnimation]),
        builder: (context, child) {
          // Option 1: Simple linear movement that smoothly loops
          final carLeft = _carAnimation.value * (fullWidth + carSize) - carSize;

          // Option 2: Sine wave movement for more natural motion
          // final carLeft = (fullWidth - carSize) *
          //     (0.5 + 0.5 * math.sin(_carAnimation.value * 2 * math.pi));

          final roadLeft = (_roadAnimation.value * fullWidth) % roadSegmentWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Moving road effect using repeating segments
              Positioned(
                bottom: 0,
                left: -roadLeft,
                child: Row(
                  children: List.generate(50, (index) {
                    return Container(
                      width: roadSegmentWidth,
                      height: lineHeight,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: MyColor.getPrimaryColor().withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(lineHeight / 2),
                      ),
                    );
                  }),
                ),
              ),

              // Moving car above the animated road
              Positioned(
                bottom: -9,
                left: carLeft.clamp(-carSize, fullWidth),
                child: Opacity(
                  // Option 4: Fade out when exiting, fade in when entering
                  opacity: _getCarOpacity(carLeft, fullWidth),
                  child: Image.asset(
                    MyIcons.carIcon,
                    width: carSize,
                    height: carSize,
                    color: MyColor.getPrimaryColor(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper function to calculate car opacity for smooth entry/exit
  double _getCarOpacity(double carLeft, double fullWidth) {
    const fadeDistance = 30.0; // Distance over which to fade

    if (carLeft < 0) {
      // Fading in from left
      return ((carLeft + carSize) / fadeDistance).clamp(0.0, 1.0);
    } else if (carLeft > fullWidth - carSize) {
      // Fading out to right
      return ((fullWidth - carLeft) / fadeDistance).clamp(0.0, 1.0);
    }
    return 1.0; // Fully visible
  }
}
