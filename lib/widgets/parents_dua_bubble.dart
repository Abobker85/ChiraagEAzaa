import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'parents_memorial_card.dart';

/// Global draggable Liquid Glass floating bubble shown across every screen.
/// Tapping opens a dialog displaying the Parents' Dua / Memorial card.
class ParentsDuaBubble extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const ParentsDuaBubble({
    super.key,
    required this.navigatorKey,
  });

  @override
  State<ParentsDuaBubble> createState() => _ParentsDuaBubbleState();
}

class _ParentsDuaBubbleState extends State<ParentsDuaBubble> {
  // Position from top-left once dragged; null uses default bottom-right anchor.
  Offset? _offset;
  bool _dialogOpen = false;

  static const double _bubbleWidth = 88;
  static const double _bubbleHeight = 40;

  Future<void> _openParentsDua() async {
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null || _dialogOpen) return;

    HapticFeedback.lightImpact();
    setState(() => _dialogOpen = true);
    try {
      await showDialog<void>(
        context: navContext,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.62),
        builder: (ctx) {
          final colors = AppColors.of(ctx);
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final surfaceColor = isDark ? const Color(0xFF181E1A) : const Color(0xFFFFFDF8);
          final borderColor = isDark
              ? AppTheme.gold.withValues(alpha: 0.55)
              : const Color(0xFF9A7B2C).withValues(alpha: 0.65);

          return Dialog(
            backgroundColor: surfaceColor,
            surfaceTintColor: Colors.transparent,
            elevation: 16,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: borderColor, width: 1.4),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 8, 6),
                    child: Row(
                      children: [
                        const Text('🤲', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Parents Dua',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF144A20),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(
                            Icons.close_rounded,
                            size: 21,
                            color: isDark ? Colors.white70 : const Color(0xFF2D3631),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 0.6, color: colors.separator),
                  const Flexible(
                    child: SingleChildScrollView(
                      child: ParentsMemorialCard(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    final padding = media.padding;

    final minX = padding.left + 10;
    final maxX = (size.width - padding.right - _bubbleWidth - 10).clamp(minX, double.infinity);
    final minY = padding.top + kToolbarHeight + 8;
    final maxY = (size.height - padding.bottom - _bubbleHeight - 88).clamp(minY, double.infinity);

    final effectiveOffset = _offset == null
        ? Offset(maxX, maxY)
        : Offset(
            _offset!.dx.clamp(minX, maxX),
            _offset!.dy.clamp(minY, maxY),
          );

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      left: effectiveOffset.dx,
      top: effectiveOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final current = _offset ?? Offset(maxX, maxY);
            _offset = Offset(
              (current.dx + details.delta.dx).clamp(minX, maxX),
              (current.dy + details.delta.dy).clamp(minY, maxY),
            );
          });
        },
        onPanEnd: (_) {
          // Snap gently to the nearest horizontal edge (iOS PiP feel)
          if (_offset == null) return;
          final snapX = (_offset!.dx + _bubbleWidth / 2) < size.width / 2 ? minX : maxX;
          setState(() {
            _offset = Offset(snapX, _offset!.dy.clamp(minY, maxY));
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Semantics(
            button: true,
            label: 'Parents Dua',
            child: InkWell(
              key: const Key('parents_dua_bubble'),
              borderRadius: BorderRadius.circular(24),
              onTap: _openParentsDua,
              child: Ink(
                width: _bubbleWidth,
                height: _bubbleHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xE81A5C28),
                      Color(0xE80D3616),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.85),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🤲', style: TextStyle(fontSize: 15)),
                    SizedBox(width: 5),
                    Text(
                      'Dua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
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
