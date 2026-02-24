import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class GlowingFab extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String? label;

  const GlowingFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  State<GlowingFab> createState() => _GlowingFabState();
}

class _GlowingFabState extends State<GlowingFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: _isPressed ? 0.7 : 0.5),
                blurRadius: _isPressed ? 35 : 30,
                spreadRadius: _isPressed ? 3 : 1,
              ),
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.black,
            size: 36,
          ),
        ),
      ),
    );
  }
}