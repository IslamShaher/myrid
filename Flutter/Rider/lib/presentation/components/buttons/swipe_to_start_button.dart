import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';

/// Uber-style swipe-to-start button for shared rides
class SwipeToStartButton extends StatefulWidget {
  final VoidCallback onStart;
  final String text;
  final bool isLoading;

  const SwipeToStartButton({
    super.key,
    required this.onStart,
    this.text = "Swipe to Start Ride",
    this.isLoading = false,
  });

  @override
  State<SwipeToStartButton> createState() => _SwipeToStartButtonState();
}

class _SwipeToStartButtonState extends State<SwipeToStartButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _animationController;

  final double _buttonHeight = 60.0;
  final double _thumbSize = 56.0;
  final double _padding = 2.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _maxDrag => MediaQuery.of(context).size.width - _thumbSize - (_padding * 2) - 40;

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isCompleted || widget.isLoading) return;

    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) {
        _dragPosition = 0;
      } else if (_dragPosition > _maxDrag) {
        _dragPosition = _maxDrag;
        _completeSwipe();
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isCompleted || widget.isLoading) return;

    // If dragged more than 80% of the way, complete it
    if (_dragPosition > _maxDrag * 0.8) {
      _completeSwipe();
    } else {
      // Snap back
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  void _completeSwipe() {
    if (_isCompleted) return;
    
    setState(() {
      _isCompleted = true;
      _dragPosition = _maxDrag;
    });
    
    _animationController.forward().then((_) {
      widget.onStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _dragPosition / _maxDrag;
    final backgroundColor = progress > 0.8 
        ? MyColor.colorGreen 
        : MyColor.getPrimaryColor();

    return Container(
      height: _buttonHeight,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: backgroundColor,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Background text
          Center(
            child: Text(
              widget.text,
              style: boldDefault.copyWith(
                color: backgroundColor,
                fontSize: 16,
              ),
            ),
          ),
          // Draggable thumb
          Positioned(
            left: _padding + _dragPosition,
            top: _padding,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        _isCompleted ? Icons.check : Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

