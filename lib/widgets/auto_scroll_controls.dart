import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// Reusable smooth Auto-Scroll (Teleprompter) controller for reciters & readers.
class AutoScrollController extends ChangeNotifier {
  static const List<double> speeds = [0.5, 1.0, 1.5, 2.0, 3.0];

  int _speedIndex = 1; // 1.0x default
  bool _visible = false;
  bool _running = false;
  Timer? _timer;
  ScrollController? _attached;

  bool get isVisible => _visible;
  bool get isRunning => _running;
  double get speed => speeds[_speedIndex];

  void attach(ScrollController controller) {
    _attached = controller;
  }

  void togglePanel() {
    HapticFeedback.selectionClick();
    if (_visible) {
      stop();
      _visible = false;
    } else {
      _visible = true;
      start();
    }
    notifyListeners();
  }

  void start() {
    _timer?.cancel();
    _running = true;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final sc = _attached;
      if (sc == null || !sc.hasClients) return;
      final maxExtent = sc.position.maxScrollExtent;
      final next = sc.offset + (1.6 * speed);
      if (next >= maxExtent) {
        sc.jumpTo(maxExtent);
        pause();
      } else {
        sc.jumpTo(next);
      }
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    if (_running) {
      _running = false;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    HapticFeedback.selectionClick();
    if (_running) {
      pause();
    } else {
      start();
    }
  }

  void slower() {
    if (_speedIndex > 0) {
      HapticFeedback.selectionClick();
      _speedIndex--;
      notifyListeners();
    }
  }

  void faster() {
    if (_speedIndex < speeds.length - 1) {
      HapticFeedback.selectionClick();
      _speedIndex++;
      notifyListeners();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

/// Compact floating Teleprompter speed control pill.
class AutoScrollBar extends StatelessWidget {
  final AutoScrollController controller;

  const AutoScrollBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isVisible) return const SizedBox.shrink();
        return Material(
          color: Colors.transparent,
          child: Container(
            key: const Key('auto_scroll_bar'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.gold.withValues(alpha: 0.6), width: 1.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  key: const Key('auto_scroll_play_pause'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: controller.togglePlayPause,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      controller.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: controller.slower,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.remove_rounded, size: 16, color: colors.textPrimary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '${controller.speed.toStringAsFixed(1)}x',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: colors.accent,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: controller.faster,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.add_rounded, size: 16, color: colors.textPrimary),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  key: const Key('auto_scroll_close'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: controller.togglePanel,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
