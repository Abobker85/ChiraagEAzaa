import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/settings_service.dart';

class LyricRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isRtl;
  final VoidCallback onTap;
  final Widget? trailing;

  const LyricRow({
    super.key,
    required this.title,
    this.subtitle,
    this.isRtl = false,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        final bool useArabic = isRtl || AppTheme.containsArabic(title);
        final double titleSize = useArabic
            ? (s.rtlFontSize * 15 / 46).clamp(15.0, 24.0)
            : (s.ltrFontSize * 15 / 19).clamp(12.0, 20.0);
        final double subtitleSize = (titleSize * 0.8).clamp(10.0, 16.0);

        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: useArabic
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: useArabic
                            ? AppTheme.arabicTextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              )
                            : TextStyle(
                                fontSize: titleSize,
                                fontWeight: FontWeight.w500,
                                color: colors.textPrimary,
                              ),
                        textDirection: useArabic ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: colors.textSecondary,
                            )),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    Icon(Icons.chevron_right, color: colors.textTertiary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Divider(height: 1, thickness: 0.5, indent: 16, color: colors.separator);
  }
}

class SectionCard extends StatelessWidget {
  final List<Widget> children;
  const SectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.separator),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const SectionDivider(),
            ]
          ]),
        ),
      ),
    );
  }
}
