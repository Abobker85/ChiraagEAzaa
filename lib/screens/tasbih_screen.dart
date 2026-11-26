import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

class _TasbihPreset {
  final String label;
  final String? arabic;
  final String? transliteration;
  final int target;
  final bool isFatimaSequence;

  const _TasbihPreset({
    required this.label,
    required this.target,
    this.arabic,
    this.transliteration,
    this.isFatimaSequence = false,
  });
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with SingleTickerProviderStateMixin {
  static const List<_TasbihPreset> _presets = [
    _TasbihPreset(
      label: 'Fatima (S.A.)',
      target: 34,
      isFatimaSequence: true,
    ),
    _TasbihPreset(
      label: '33',
      target: 33,
      arabic: 'سُبْحَانَ اللَّهِ',
      transliteration: 'SubhanAllah',
    ),
    _TasbihPreset(
      label: '99',
      target: 99,
      arabic: 'يَا اللَّهُ',
      transliteration: 'Asma ul Husna',
    ),
    _TasbihPreset(
      label: '100',
      target: 100,
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      transliteration: 'Istighfar',
    ),
    _TasbihPreset(
      label: '313',
      target: 313,
      arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَآلِ مُحَمَّدٍ',
      transliteration: 'Salawat',
    ),
    _TasbihPreset(
      label: '1000',
      target: 1000,
      arabic: 'ذِكْرُ اللَّهِ',
      transliteration: 'Dhikr',
    ),
  ];

  static const _fatimaStages = [
    (arabic: 'اللَّهُ أَكْبَرُ', latin: 'Allahu Akbar', target: 34),
    (arabic: 'الْحَمْدُ لِلَّهِ', latin: 'Alhamdulillah', target: 33),
    (arabic: 'سُبْحَانَ اللَّهِ', latin: 'SubhanAllah', target: 33),
  ];

  int _presetIdx = 0;
  int _fatimaStage = 0;
  int _count = 0;
  int _roundsCompleted = 0;
  late AnimationController _anim;
  late Animation<double> _scale;

  _TasbihPreset get _preset => _presets[_presetIdx];

  int get _target => _preset.isFatimaSequence
      ? _fatimaStages[_fatimaStage].target
      : _preset.target;

  String get _currentArabic => _preset.isFatimaSequence
      ? _fatimaStages[_fatimaStage].arabic
      : (_preset.arabic ?? '');

  String get _currentLatin => _preset.isFatimaSequence
      ? _fatimaStages[_fatimaStage].latin
      : (_preset.transliteration ?? 'Dhikr');

  double get _progress => (_count / _target).clamp(0.0, 1.0);

  int get _beadCount => _target <= 34 ? _target : 33;

  int get _completedBeads => (_progress * _beadCount).floor();

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    _toastEntry?.remove();
    super.dispose();
  }

  void _tap() {
    setState(() => _count++);
    HapticFeedback.lightImpact();
    _anim.forward().then((_) {
      if (mounted) _anim.reverse();
    });

    if (_count == _target) {
      HapticFeedback.mediumImpact();
      if (_preset.isFatimaSequence && _fatimaStage < _fatimaStages.length - 1) {
        final doneName = _fatimaStages[_fatimaStage].latin;
        _showToast('$doneName ($_target) complete');
        Future.delayed(const Duration(milliseconds: 550), () {
          if (!mounted) return;
          setState(() {
            _fatimaStage++;
            _count = 0;
          });
        });
      } else {
        _showToast(
          _preset.isFatimaSequence
              ? 'Tasbih Bibi Fatima Zahra (S.A.) complete'
              : '$_target complete',
        );
        setState(() => _roundsCompleted++);
      }
    }
  }

  void _undo() {
    if (_count <= 0) return;
    HapticFeedback.selectionClick();
    setState(() => _count--);
  }

  void _reset() {
    HapticFeedback.selectionClick();
    setState(() {
      _count = 0;
      _fatimaStage = 0;
    });
  }

  void _selectPreset(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _presetIdx = idx;
      _fatimaStage = 0;
      _count = 0;
    });
  }

  OverlayEntry? _toastEntry;
  void _showToast(String msg) {
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 110,
        left: 20,
        right: 20,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xE6141816),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13.5),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_toastEntry!);
    Future.delayed(const Duration(seconds: 2), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heroGradient = isDark
        ? const [Color(0xFF0E2915), Color(0xFF174523)]
        : const [Color(0xFF0D3B18), Color(0xFF1A5C28)];
    final remaining = (_target - _count).clamp(0, _target);

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.textPrimary,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: const Text('Digital Tasbih'),
        actions: [
          IconButton(
            tooltip: 'Undo Last Tap',
            icon: Icon(
              Icons.undo_rounded,
              color: _count > 0 ? colors.accent : colors.textTertiary,
            ),
            onPressed: _count > 0 ? _undo : null,
          ),
          IconButton(
            tooltip: 'Reset Counter',
            icon: Icon(Icons.refresh_rounded, color: colors.accent),
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        child: Column(
          children: [
            // Preset selector chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final selected = i == _presetIdx;
                  return ChoiceChip(
                    label: Text(
                      _presets[i].label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.white : colors.textPrimary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: colors.accent,
                    backgroundColor: colors.card,
                    side: BorderSide(
                      color: selected ? colors.accent : colors.separator,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    showCheckmark: false,
                    onSelected: (_) => _selectPreset(i),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Emerald Sanctuary Dhikr Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: heroGradient,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.38),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D3B18).withValues(alpha: isDark ? 0.35 : 0.16),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.gold.withValues(alpha: 0.45),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            _preset.isFatimaSequence
                                ? 'Tasbih Bibi Fatima Zahra (S.A.)'
                                : _preset.transliteration ?? 'Sacred Dhikr',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF6DF96),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Target $_target',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentArabic.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      _currentArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabicTextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _currentLatin,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE7EFEA),
                    ),
                  ),
                  if (_preset.isFatimaSequence) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: List.generate(_fatimaStages.length, (i) {
                        final st = _fatimaStages[i];
                        final isCurrent = i == _fatimaStage;
                        final isDone = i < _fatimaStage;
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFFE7C462)
                                  : Colors.white.withValues(alpha: isDone ? 0.18 : 0.10),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: isCurrent
                                    ? const Color(0xFFF6DF96)
                                    : Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${st.target}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent ? const Color(0xFF122616) : Colors.white,
                                  ),
                                ),
                                Text(
                                  st.latin,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    color: isCurrent
                                        ? const Color(0xFF122616)
                                        : Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Main Tactile Bead-Ring Dial Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.separator),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 244,
                    height: 244,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(244, 244),
                          painter: _BeadRingPainter(
                            totalBeads: _beadCount,
                            completedBeads: _completedBeads,
                            activeColor: colors.accent,
                            inactiveColor: colors.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        ScaleTransition(
                          scale: _scale,
                          child: GestureDetector(
                            onTap: _tap,
                            child: Container(
                              width: 174,
                              height: 174,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.paperBg,
                                border: Border.all(
                                  color: colors.gold.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.accent.withValues(alpha: 0.14),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'COUNT',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$_count',
                                    style: TextStyle(
                                      fontSize: 54,
                                      fontWeight: FontWeight.w700,
                                      color: colors.accent,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: colors.accentSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Tap to recite',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: colors.accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _count > 0 ? _undo : null,
                        icon: const Icon(Icons.undo_rounded, size: 15),
                        label: const Text('Undo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.separator),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: colors.goldSoft,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.gold.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _roundsCompleted > 0
                              ? '$_roundsCompleted ${_roundsCompleted == 1 ? 'round' : 'rounds'} done'
                              : '$remaining left in stage',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFE7C76E) : const Color(0xFF705310),
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.accent,
                          side: BorderSide(color: colors.accent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  final int totalBeads;
  final int completedBeads;
  final Color activeColor;
  final Color inactiveColor;

  _BeadRingPainter({
    required this.totalBeads,
    required this.completedBeads,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 10;

    for (int i = 0; i < totalBeads; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / totalBeads);
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final isActive = i < completedBeads;
      final isHead = i == 0;
      final beadRadius = isHead ? 6.0 : (isActive ? 5.0 : 4.2);

      final paint = Paint()
        ..color = isActive || isHead ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(pos, beadRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BeadRingPainter old) {
    return old.totalBeads != totalBeads ||
        old.completedBeads != completedBeads ||
        old.activeColor != activeColor ||
        old.inactiveColor != inactiveColor;
  }
}
