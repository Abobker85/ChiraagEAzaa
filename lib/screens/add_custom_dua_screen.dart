import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../services/dua_language_service.dart';

/// Dedicated page allowing users to submit their own custom Dua (Arabic, Roman,
/// and/or English) and save it directly into the searchable Dua & Spiritual Portal index.
class AddCustomDuaScreen extends StatefulWidget {
  final String initialCategoryKey;

  const AddCustomDuaScreen({
    super.key,
    this.initialCategoryKey = 'duas',
  });

  @override
  State<AddCustomDuaScreen> createState() => _AddCustomDuaScreenState();
}

class _AddCustomDuaScreenState extends State<AddCustomDuaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _arabicCtrl = TextEditingController();
  final _romanCtrl = TextEditingController();
  final _englishCtrl = TextEditingController();

  late String _categoryKey;
  bool _saving = false;
  String? _contentError;

  static const _categories = [
    (key: 'duas', label: 'Duas'),
    (key: 'ziyaraat', label: 'Ziyaraat'),
    (key: 'munaejaat', label: 'Munajaat'),
    (key: 'nouhay', label: 'Nouhay'),
    (key: 'marsias', label: 'Marsias'),
    (key: 'urduMarsiye', label: 'Urdu Poem'),
  ];

  @override
  void initState() {
    super.initState();
    _categoryKey = _categories.any((c) => c.key == widget.initialCategoryKey)
        ? widget.initialCategoryKey
        : 'duas';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _arabicCtrl.dispose();
    _romanCtrl.dispose();
    _englishCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    final hasAnyText = _arabicCtrl.text.trim().isNotEmpty ||
        _romanCtrl.text.trim().isNotEmpty ||
        _englishCtrl.text.trim().isNotEmpty;

    if (!hasAnyText) {
      setState(() {
        _contentError = 'Please enter the Dua in at least one language (Arabic, Roman, or English).';
      });
      return;
    }
    setState(() => _contentError = null);
    if (!valid) return;

    setState(() => _saving = true);
    try {
      HapticFeedback.lightImpact();
      final saved = await DatabaseService.instance.addCustomDua(
        categoryKey: _categoryKey,
        title: _titleCtrl.text,
        subtitle: _subtitleCtrl.text,
        arabic: _arabicCtrl.text,
        roman: _romanCtrl.text,
        english: _englishCtrl.text,
      );
      await DuaLanguageService.instance.ensureLoaded();
      DuaLanguageService.instance.registerCustomDua(
        title: saved.title,
        subtitle: _subtitleCtrl.text,
        arabic: _arabicCtrl.text,
        roman: _romanCtrl.text,
        english: _englishCtrl.text,
      );
      if (!mounted) return;
      Navigator.pop(context, saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Dua: $e')),
      );
    }
  }

  InputDecoration _inputDecoration(
    AppColors colors, {
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: colors.card,
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13.5),
      hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.separator),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.separator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors.accent, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Custom Dua',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.accentSoft.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: colors.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Submit your own Dua in Arabic, Roman, or English. It will be saved offline and added to the searchable index.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Section',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = _categoryKey == c.key;
                return ChoiceChip(
                  label: Text(c.label),
                  selected: selected,
                  selectedColor: colors.accent,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : colors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _categoryKey = c.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('custom_dua_title_field'),
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(fontSize: 15, color: colors.textPrimary),
              decoration: _inputDecoration(
                colors,
                label: 'Dua Title *',
                hint: 'e.g., Dua for Parents, Dua for Shifa',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Please enter a title for the Dua' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('custom_dua_subtitle_field'),
              controller: _subtitleCtrl,
              style: TextStyle(fontSize: 14, color: colors.textPrimary),
              decoration: _inputDecoration(
                colors,
                label: 'Subtitle / Source (Optional)',
                hint: 'e.g., Taught by Imam Sadiq (a.s.) or Personal Dua',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('custom_dua_arabic_field'),
              controller: _arabicCtrl,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              minLines: 4,
              maxLines: 10,
              style: AppTheme.arabicTextStyle(
                fontSize: 24,
                height: 1.9,
                color: colors.textPrimary,
              ),
              decoration: _inputDecoration(
                colors,
                label: 'Arabic Text (العربية)',
                hint: 'اَللّٰهُمَّ صَلِّ عَلٰى مُحَمَّدٍ وَاٰلِ مُحَمَّدٍ...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('custom_dua_roman_field'),
              controller: _romanCtrl,
              minLines: 3,
              maxLines: 8,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: colors.textPrimary),
              decoration: _inputDecoration(
                colors,
                label: 'Roman Transliteration (Optional)',
                hint: 'Allahumma salli ala Muhammadin wa ali Muhammad...',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('custom_dua_english_field'),
              controller: _englishCtrl,
              minLines: 3,
              maxLines: 8,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: colors.textPrimary),
              decoration: _inputDecoration(
                colors,
                label: 'English Translation (Optional)',
                hint: 'O Allah, send blessings upon Muhammad and his Progeny...',
              ),
            ),
            if (_contentError != null) ...[
              const SizedBox(height: 10),
              Text(
                _contentError!,
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                key: const Key('custom_dua_submit_btn'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _saving ? 'Saving...' : 'Save Dua to Index',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
