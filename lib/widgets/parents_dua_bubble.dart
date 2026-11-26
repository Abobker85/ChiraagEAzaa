import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'parents_memorial_card.dart';

/// Opens the high-contrast Parents Dua / Memorial tribute dialog.
Future<void> showParentsDuaDialog(BuildContext context) {
  HapticFeedback.lightImpact();
  return showDialog<void>(
    context: context,
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
        insetPadding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
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
                padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      size: 19,
                      color: isDark ? AppTheme.gold : const Color(0xFF1A5C28),
                    ),
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
                    Material(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.14)
                          : const Color(0xFFE5E9E6),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Close',
                        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? Colors.white : const Color(0xFF141816),
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
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
}

/// Draggable floating bubble shown on the Home page when used standalone.
/// Tapping toggles a dialog displaying the Parents' Dua / Memorial card.
class ParentsDuaBubble extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;

  const ParentsDuaBubble({
    super.key,
    this.navigatorKey,
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

  Future<void> _toggleParentsDua() async {
    if (_dialogOpen) {
      HapticFeedback.lightImpact();
      final navContext = widget.navigatorKey?.currentContext ?? context;
      if (navContext.mounted) {
        await Navigator.of(navContext).maybePop();
      } else {
        await widget.navigatorKey?.currentState?.maybePop();
      }
      return;
    }

    final navContext = widget.navigatorKey?.currentContext ?? context;
    if (!navContext.mounted) return;

    HapticFeedback.lightImpact();
    setState(() => _dialogOpen = true);
    try {
      await showParentsDuaDialog(navContext);
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : media.size.width;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : media.size.height;
        final padding = media.padding;

        final minX = padding.left + 10;
        final maxX = (width - padding.right - _bubbleWidth - 10).clamp(minX, double.infinity);
        const minY = 10.0;
        final maxY = (height - padding.bottom - _bubbleHeight - 96).clamp(minY, double.infinity);

        final effectiveOffset = _offset == null
            ? Offset(maxX, maxY)
            : Offset(
                _offset!.dx.clamp(minX, maxX),
                _offset!.dy.clamp(minY, maxY),
              );

        return Stack(
          children: [
            AnimatedPositioned(
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
                  if (_offset == null) return;
                  final snapX = (_offset!.dx + _bubbleWidth / 2) < width / 2 ? minX : maxX;
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
                      onTap: _toggleParentsDua,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _dialogOpen
                                  ? Icons.close_rounded
                                  : Icons.volunteer_activism_rounded,
                              size: 16,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _dialogOpen ? 'Hide' : 'Dua',
                              style: const TextStyle(
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
            ),
          ],
        );
      },
    );
  }
}
