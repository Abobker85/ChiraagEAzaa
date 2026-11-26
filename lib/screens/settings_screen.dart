import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';
import '../services/user_data_service.dart';
import '../widgets/parents_memorial_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _s = AppSettings.instance;
  AuthorizationStatus? _pushStatus;

  @override
  void initState() {
    super.initState();
    _loadPushStatus();
  }

  Future<void> _loadPushStatus() async {
    if (kIsWeb) return;

    final status = await PushNotificationService.instance.getStatus();
    if (mounted) setState(() => _pushStatus = status);
  }

  Future<void> _togglePush() async {
    if (kIsWeb) return;

    if (_pushStatus == AuthorizationStatus.authorized) {
      await PushNotificationService.instance.unsubscribeFromTopic('general');
      _showToast('Notifications disabled');
      await _loadPushStatus();
    } else {
      final granted = await PushNotificationService.instance.requestPermission();
      if (granted) {
        await PushNotificationService.instance.subscribeToTopic('general');
        final token = await PushNotificationService.instance.getToken();
        debugPrint('FCM Token: $token');
        _showToast('Notifications enabled 🔔');
      } else {
        _showToast('Permission denied');
      }
      await _loadPushStatus();
    }
  }

  OverlayEntry? _toastEntry;
  void _showToast(String msg) {
    _toastEntry?.remove();
    final overlay = Overlay.of(context);
    _toastEntry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 80, left: 0, right: 0,
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
    Future.delayed(const Duration(milliseconds: 2500), () {
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
        title: const Text('Settings'),
      ),
      body: AnimatedBuilder(
        animation: _s,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 110),
          children: [
            _sectionHeader('Appearance', colors),
            _settingsCard(colors, [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_rounded, size: 16),
                          ),
                        ],
                        selected: {_s.themeMode},
                        onSelectionChanged: (sel) {
                          _s.themeMode = sel.first;
                          _s.save();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ]),
            _sectionHeader('Font Size', colors),
            _settingsCard(colors, [
              _sliderRow(
                colors: colors,
                label: 'Roman / English',
                sub: 'Nouhay · Marsias · Salaam',
                value: _s.ltrFontSize.clamp(14.0, 26.0),
                min: 14, max: 26,
                display: '${_s.ltrFontSize.round()}px',
                onChanged: (v) { _s.ltrFontSize = v; _s.save(); },
              ),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _sliderRow(
                colors: colors,
                label: 'Urdu',
                sub: 'Urdu Marsiye · Translations',
                value: _s.rtlFontSize.clamp(28.0, 56.0),
                min: 28, max: 56,
                display: '${_s.rtlFontSize.round()}px',
                onChanged: (v) { _s.rtlFontSize = v; _s.save(); },
              ),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _sliderRow(
                colors: colors,
                label: 'Arabic',
                sub: 'Duas · Ziyaraat · Arabic text',
                value: _s.arabicFontSize.clamp(32.0, 72.0),
                min: 32, max: 72,
                display: '${_s.arabicFontSize.round()}px',
                onChanged: (v) { _s.arabicFontSize = v; _s.save(); },
              ),
            ]),
            _sectionHeader('Spacing', colors),
            _settingsCard(colors, [
              _sliderRow(
                colors: colors,
                label: 'Paragraph spacing',
                value: _s.paraSpacing.clamp(0.0, 48.0),
                min: 0, max: 48,
                display: '${_s.paraSpacing.round()}px',
                onChanged: (v) { _s.paraSpacing = v; _s.save(); },
              ),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _sliderRow(
                colors: colors,
                label: 'Line height',
                value: _s.lineHeight.clamp(1.3, 2.5),
                min: 1.3, max: 2.5,
                divisions: 12,
                display: _s.lineHeight.toStringAsFixed(1),
                onChanged: (v) {
                  _s.lineHeight = double.parse(v.toStringAsFixed(1));
                  _s.save();
                },
              ),
            ]),
            _sectionHeader('General', colors),
            _settingsCard(colors, [
              ListTile(
                title: const Text(
                  'Reset to defaults',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                trailing: const Icon(Icons.refresh, color: AppTheme.errorRed),
                onTap: () {
                  _s.reset();
                  _showToast('Reset to defaults');
                },
              ),
            ]),
            _sectionHeader('Backup & Restore', colors),
            _settingsCard(colors, [
              ListTile(
                key: const Key('settings_export_backup_btn'),
                leading: Icon(Icons.upload_rounded, color: colors.accent),
                title: Text('Export Backup (Copy JSON)', style: TextStyle(color: colors.textPrimary)),
                subtitle: Text(
                  'Copy Bookmarks, Custom Duas, Majlis Playlists, Khatm & Notes',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: _exportBackup,
              ),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              ListTile(
                key: const Key('settings_import_backup_btn'),
                leading: Icon(Icons.download_rounded, color: colors.accent),
                title: Text('Restore from Backup JSON', style: TextStyle(color: colors.textPrimary)),
                subtitle: Text(
                  'Paste a previously exported backup to restore your data',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                onTap: _showImportBackupDialog,
              ),
            ]),
            _sectionHeader('About', colors),
            _settingsCard(colors, [
              _infoRow(
                colors,
                'Chiraag e Azaa',
                'Version 1.0',
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  ),
                ),
                trailing: Text('v1.0', style: TextStyle(color: colors.textSecondary)),
              ),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _infoRow(colors, 'Total Lyrics', 'Nouhay, Marsias, Duas & more', trailing: Text('5,128', style: TextStyle(color: colors.textSecondary))),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _infoRow(colors, 'Offline Mode', 'Works without internet', trailing: const Text('✅', style: TextStyle(fontSize: 20))),
            ]),
            _sectionHeader('Notifications & Reminders', colors),
            _settingsCard(colors, [
              _dailyReminderTile(colors),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _testNotificationTile(colors),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              _pushRow(colors),
            ]),
            _sectionHeader('Credits', colors),
            _settingsCard(colors, [
              _infoRow(colors, 'Designed & Developed by', 'Mir Sajjad Ali', trailing: const Text('💚', style: TextStyle(fontSize: 20))),
              Divider(height: 1, thickness: 0.5, color: colors.separator),
              ListTile(
                title: Text('Email', style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('gisdevpr31@gmail.com', style: TextStyle(color: colors.textSecondary)),
                trailing: const Text('✉️', style: TextStyle(fontSize: 18)),
              ),
            ]),
            _sectionHeader('Request', colors),
            _settingsCard(colors, const [
              ParentsMemorialCard(),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      final jsonStr = await UserDataService.instance.exportBackupJson();
      await Clipboard.setData(ClipboardData(text: jsonStr));
      _showToast('Backup JSON copied to clipboard');
    } catch (e) {
      _showToast('Export failed: $e');
    }
  }

  Future<void> _showImportBackupDialog() async {
    final ctrl = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: TextField(
          key: const Key('restore_backup_input'),
          controller: ctrl,
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: 'Paste exported Chiraag e Azaa JSON backup here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('restore_backup_confirm_btn'),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final summary = await UserDataService.instance.importBackupJson(raw);
      _showToast(summary);
    } catch (e) {
      _showToast('Invalid backup JSON');
    }
  }

  Widget _pushRow(AppColors colors) {
    if (kIsWeb) {
      return ListTile(
        title: Text('Push Notifications', style: TextStyle(color: colors.textPrimary)),
        subtitle: Text(
          'Available in Android and iOS builds',
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        trailing: Icon(Icons.notifications_off_outlined, color: colors.textTertiary),
      );
    }

    final enabled = _pushStatus == AuthorizationStatus.authorized;
    final denied = _pushStatus == AuthorizationStatus.denied;
    final icon = enabled ? '🔔' : denied ? '🚫' : '🔕';
    final sub = enabled
        ? 'Tap to disable'
        : denied
            ? 'Blocked — enable in device settings'
            : 'Tap to enable';
    return ListTile(
      title: Text('Push Notifications', style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(sub, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      trailing: _pushStatus == null
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(icon, style: const TextStyle(fontSize: 20)),
      onTap: denied ? null : _togglePush,
    );
  }

  Widget _dailyReminderTile(AppColors colors) {
    if (kIsWeb) return const SizedBox.shrink();
    return SwitchListTile(
      secondary: Icon(Icons.alarm_on_rounded, color: colors.accent),
      title: Text('Daily Recitation Reminders', style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(
        'Device Language: ${PushNotificationService.getDeviceLanguageDisplay()}',
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      activeThumbColor: colors.accent,
      activeTrackColor: colors.accentSoft,
      value: _s.dailyRemindersEnabled,
      onChanged: (val) async {
        _s.dailyRemindersEnabled = val;
        await _s.save();
        if (val) {
          final granted = await PushNotificationService.instance.requestPermission();
          if (granted) {
            await PushNotificationService.instance.scheduleDailyReminders();
            _showToast('Daily reminders enabled 🔔');
          } else {
            _showToast('Notification permission denied');
          }
        } else {
          await PushNotificationService.instance.cancelDailyReminders();
          _showToast('Daily reminders disabled');
        }
      },
    );
  }

  Widget _testNotificationTile(AppColors colors) {
    if (kIsWeb) return const SizedBox.shrink();
    return ListTile(
      leading: Icon(Icons.notifications_active_outlined, color: colors.accent),
      title: Text('Send Test Notification Now', style: TextStyle(color: colors.textPrimary)),
      subtitle: Text(
        'Sends a system alert in ${PushNotificationService.getDeviceLanguageDisplay()}',
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colors.textTertiary),
      onTap: () async {
        final success = await PushNotificationService.instance.showTestNotification();
        if (success) {
          _showToast('Test notification sent (${PushNotificationService.getDeviceLanguageDisplay()}) 📲');
        } else {
          _showToast('Could not send notification. Please grant permission.');
        }
      },
    );
  }

  Widget _sectionHeader(String title, AppColors colors) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _settingsCard(AppColors colors, List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    decoration: BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: colors.separator),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        type: MaterialType.transparency,
        child: Column(children: children),
      ),
    ),
  );

  Widget _sliderRow({
    required AppColors colors,
    required String label,
    String? sub,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                  if (sub != null)
                    Text(sub, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                ]),
              ),
              Text(display, style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: colors.accent,
              thumbColor: colors.accent,
              inactiveTrackColor: colors.accent.withValues(alpha: 0.2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(AppColors colors, String label, String sub, {Widget? trailing, Widget? leading}) => ListTile(
    leading: leading,
    title: Text(label, style: TextStyle(fontSize: 15, color: colors.textPrimary)),
    subtitle: Text(sub, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
    trailing: trailing,
  );
}
