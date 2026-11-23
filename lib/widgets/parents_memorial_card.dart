import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable memorial card requesting Surah Al-Fatiha for the client's parents.
/// Used both in the Settings "REQUEST" section and in the global Parents Dua popup.
class ParentsMemorialCard extends StatelessWidget {
  const ParentsMemorialCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppTheme.textPrimary;
    final secondaryText = isDark ? Colors.white70 : AppTheme.textSecondary;
    final accentColor = isDark ? AppTheme.gold : const Color(0xFF8A7230);
    final frameBorderColor = isDark
        ? AppTheme.gold.withValues(alpha: 0.5)
        : const Color(0xFFC5B07A);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: AppTheme.arabicTextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: accentColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We humbly request all readers to kindly recite Surah Al-Fatiha for the Isaal-e-Sawab of our beloved parents.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: frameBorderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: AspectRatio(
                  aspectRatio: 390 / 381,
                  child: Image.asset(
                    'assets/images/memorial_parents.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Al-Haj O Zawar Janab Mir Hussain Ali',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ex-Secretary, Anjuman-e-Parwanah Jaffariyah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Son of Janab Mir Jamal Ali (Marhoom)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 56,
                child: Divider(color: frameBorderColor, thickness: 0.9),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 6,
                    height: 6,
                    color: accentColor,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Divider(color: frameBorderColor, thickness: 0.9),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Al-Haj O Zawaraa Syeda Zainab Fatima',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Daughter of Janab Mir Ahmed Ali (Marhoom)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'May Allah (SWT) grant them the highest place in Jannatul Firdaus and fill their graves with light. Ameen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.45,
              color: primaryText,
            ),
          ),
        ],
      ),
    );
  }
}
