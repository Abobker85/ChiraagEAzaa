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
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final s = AppSettings.instance;
        // Use a scaled-down version of the content font for list titles
        // so they grow/shrink proportionally when the user adjusts font size.
        // LTR content: base 15 → scales with ltrFontSize (default 19).
        // RTL content: base 15 → scales with rtlFontSize (default 46), but
        //   list titles are short so we cap at a sensible size.
        final double titleSize = isRtl
            ? (s.rtlFontSize * 15 / 46).clamp(13.0, 22.0)
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
                    crossAxisAlignment: isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                          fontFamily: isRtl ? 'NotoNaskhArabic' : null,
                        ),
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: AppTheme.textSecondary,
                            )),
                      ],
                    ],
                  ),
                ),
                trailing ??
                    const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 20),
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
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 0.5, indent: 16, color: AppTheme.separator);
}

class SectionCard extends StatelessWidget {
  final List<Widget> children;
  const SectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const SectionDivider(),
          ]
        ]),
      ),
    );
  }
}
