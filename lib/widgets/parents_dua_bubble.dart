import 'package:flutter/material.dart';
import '../theme.dart';
import 'parents_memorial_card.dart';

/// Global draggable floating bubble shown across every screen in the app.
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

  static const double _bubbleWidth = 92;
  static const double _bubbleHeight = 42;

  Future<void> _openParentsDua() async {
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null || _dialogOpen) return;

    setState(() => _dialogOpen = true);
    try {
      await showDialog<void>(
        context: navContext,
        barrierDismissible: true,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final surfaceColor = isDark ? const Color(0xFF1E1E1E) : AppTheme.card;
          final borderColor = isDark
              ? AppTheme.gold.withValues(alpha: 0.45)
              : AppTheme.gold.withValues(alpha: 0.55);

          return Dialog(
            backgroundColor: surfaceColor,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: borderColor, width: 1.2),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 8, 4),
                    child: Row(
                      children: [
                        const Text('🤲', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Parents Dua',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppTheme.green,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white70 : AppTheme.textSecondary,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
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

    final minX = padding.left + 8;
    final maxX = (size.width - padding.right - _bubbleWidth - 8).clamp(minX, double.infinity);
    final minY = padding.top + kToolbarHeight + 8;
    final maxY = (size.height - padding.bottom - _bubbleHeight - 76).clamp(minY, double.infinity);

    final effectiveOffset = _offset == null
        ? Offset(maxX, maxY)
        : Offset(
            _offset!.dx.clamp(minX, maxX),
            _offset!.dy.clamp(minY, maxY),
          );

    return Positioned(
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
                      Color(0xFF1A5C28),
                      Color(0xFF0F3B19),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.85),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🤲', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 5),
                    Text(
                      'Dua',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
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
