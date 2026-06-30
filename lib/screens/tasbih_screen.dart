import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  static const _targets = [33, 99, 100, 313, 1000];
  int _count = 0;
  int _targetIdx = 0;
  late AnimationController _anim;
  late Animation<double> _scale;

  int get _target => _targets[_targetIdx];
  double get _progress => (_count / _target).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _tap() {
    setState(() => _count++);
    HapticFeedback.lightImpact();
    _anim.forward().then((_) => _anim.reverse());
    if (_count == _target) {
      _showToast('🎉 $_target complete!');
    }
  }

  void _reset() {
    setState(() => _count = 0);
  }

  void _nextTarget() {
    setState(() {
      _targetIdx = (_targetIdx + 1) % _targets.length;
      _count = 0;
    });
  }

  OverlayEntry? _toastEntry;
  void _showToast(String msg) {
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 80,
        left: 0, right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),

            // Count display
            Text(
              '$_count',
              style: const TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: AppTheme.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_count / $_target',
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 32),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                backgroundColor: AppTheme.greenPale,
                valueColor: const AlwaysStoppedAnimation(AppTheme.green),
              ),
            ),

            const SizedBox(height: 48),

            // Tap button
            ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _tap,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.green,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.green.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('☝️', style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.green,
                    side: const BorderSide(color: AppTheme.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _nextTarget,
                  icon: const Icon(Icons.track_changes, size: 16),
                  label: Text('Target: $_target'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.green,
                    side: const BorderSide(color: AppTheme.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
