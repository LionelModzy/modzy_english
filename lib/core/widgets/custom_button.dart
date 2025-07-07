import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../constants/app_colors.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isAdmin;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.textColor,
    this.width,
    this.height = 56,
    this.borderRadius,
    this.isAdmin = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
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

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: isEnabled ? _onTapDown : null,
            onTapUp: isEnabled ? _onTapUp : null,
            onTapCancel: isEnabled ? _onTapCancel : null,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: widget.isOutlined
                    ? null
                    : widget.isAdmin
                        ? AppColors.adminGradient
                        : widget.color != null
                            ? LinearGradient(
                                colors: [widget.color!, widget.color!.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : AppColors.primaryGradient,
                color: widget.isOutlined
                    ? Colors.transparent
                    : null,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                border: widget.isOutlined
                    ? Border.all(
                        color: widget.isAdmin
                            ? AppColors.adminPrimary
                            : widget.color ?? AppColors.primary,
                        width: 2,
                      )
                    : null,
                boxShadow: widget.isOutlined
                    ? null
                    : [
                        BoxShadow(
                          color: (widget.isAdmin
                                  ? AppColors.adminPrimary
                                  : widget.color ?? AppColors.primary)
                              .withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? widget.onPressed : null,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null && !widget.isLoading) ...[
                          Icon(
                            widget.icon,
                            color: widget.isOutlined
                                ? (widget.isAdmin
                                    ? AppColors.adminPrimary
                                    : widget.color ?? AppColors.primary)
                                : widget.textColor ?? Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.isLoading)
                          LoadingAnimationWidget.staggeredDotsWave(
                            color: widget.isOutlined
                                ? (widget.isAdmin
                                    ? AppColors.adminPrimary
                                    : widget.color ?? AppColors.primary)
                                : widget.textColor ?? Colors.white,
                            size: 24,
                          )
                        else
                          Flexible(
                            child: Text(
                              widget.text,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isOutlined
                                    ? (widget.isAdmin
                                        ? AppColors.adminPrimary
                                        : widget.color ?? AppColors.primary)
                                    : widget.textColor ?? Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
      },
    );
  }
} 