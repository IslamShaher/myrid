import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/core/utils/style.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

/// Enhanced action button with icon, shadow, and modern styling
class EnhancedActionButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final bool isLoading;
  final bool isOutlined;
  final double? width;
  final bool isPrimary;

  const EnhancedActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
    this.isPrimary = false,
  });

  @override
  State<EnhancedActionButton> createState() => _EnhancedActionButtonState();
}

class _EnhancedActionButtonState extends State<EnhancedActionButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = widget.backgroundColor ?? 
        (widget.isPrimary ? MyColor.getPrimaryColor() : MyColor.neutral100);
    final effectiveTextColor = widget.textColor ?? 
        (widget.isOutlined ? effectiveBgColor : Colors.white);
    final effectiveIconColor = widget.iconColor ?? effectiveTextColor;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isOutlined ? Colors.transparent : effectiveBgColor,
            border: widget.isOutlined
                ? Border.all(color: effectiveBgColor, width: 2)
                : null,
            boxShadow: widget.isOutlined
                ? [
                    BoxShadow(
                      color: effectiveBgColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: effectiveBgColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: effectiveBgColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: -2,
                    ),
                  ],
            gradient: widget.isOutlined
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      effectiveBgColor,
                      effectiveBgColor.withOpacity(0.8),
                    ],
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: BorderRadius.circular(16),
              splashColor: effectiveTextColor.withOpacity(0.2),
              highlightColor: effectiveTextColor.withOpacity(0.1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: SpinKitFadingCircle(
                          color: effectiveTextColor,
                          size: 20,
                        ),
                      )
                    else if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: effectiveIconColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        widget.text.tr,
                        style: boldDefault.copyWith(
                          color: effectiveTextColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



