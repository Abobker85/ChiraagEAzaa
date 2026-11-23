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
      }
    }
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

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        title: const Text('Digital Tasbih'),
        actions: [
          IconButton(
            tooltip: 'Reset Counter',
            icon: Icon(Icons.refresh_rounded, color: colors.accent),
            onPressed: _reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
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
            const SizedBox(height: 16),

            // Main Tasbih Card with bead-ring dial
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.separator),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (_preset.isFatimaSequence)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colors.goldSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colors.gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Tasbih Bibi Fatima Zahra (S.A.)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.gold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '34 Allahu Akbar · 33 Alhamdulillah · 33 SubhanAllah',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Current Dhikr title + Arabic calligraphy
                  Text(
                    _currentLatin,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                  if (_currentArabic.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _currentArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabicTextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Target: $_target',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Circular Bead-Ring + Central Tactile Counter Button
                  SizedBox(
                    width: 248,
                    height: 248,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(248, 248),
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
                              width: 176,
                              height: 176,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.paperBg,
                                border: Border.all(
                                  color: colors.gold.withValues(alpha: 0.55),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.accent.withValues(alpha: 0.14),
                                    blurRadius: 20,
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
                                      fontSize: 11,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w600,
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
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap to recite',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
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
