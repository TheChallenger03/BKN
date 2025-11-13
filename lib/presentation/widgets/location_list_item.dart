import 'package:flutter/material.dart';
import '../../domain/entities/saved_location.dart';
import '../../core/themes/app_theme.dart';
import 'glass_card.dart';

class LocationListItem extends StatefulWidget {
  final SavedLocation location;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const LocationListItem({
    super.key,
    required this.location,
    required this.onTap,
    required this.onTogglePin,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  State<LocationListItem> createState() => _LocationListItemState();
}

class _LocationListItemState extends State<LocationListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        onTap: () {
          _controller.forward().then((_) => _controller.reverse());
          widget.onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon with gradient background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: widget.location.isPinned
                        ? AppTheme.primaryGradient
                        : LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: widget.location.isPinned
                        ? Colors.black
                        : AppTheme.primaryTeal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.location.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              widget.location.label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: widget.location.isPinned
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.location.latitude.toStringAsFixed(5)}, '
                        '${widget.location.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ActionButton(
                  icon: widget.location.isPinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  tooltip: widget.location.isPinned
                      ? 'Rimuovi pin'
                      : 'Fissa in alto',
                  onPressed: widget.onTogglePin,
                  isPrimary: widget.location.isPinned,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  tooltip: 'Condividi',
                  onPressed: widget.onShare,
                ),
                _ActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Modifica',
                  onPressed: widget.onEdit,
                ),
                _ActionButton(
                  icon: Icons.delete_outline,
                  tooltip: 'Elimina',
                  onPressed: widget.onDelete,
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    if (widget.isDestructive) {
      iconColor = Colors.red.shade400;
    } else if (widget.isPrimary) {
      iconColor = AppTheme.primaryTeal;
    } else {
      iconColor = Colors.white.withValues(alpha: 0.7);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(widget.icon),
            iconSize: 22,
            color: iconColor,
            onPressed: widget.onPressed,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        ),
      ),
    );
  }
}