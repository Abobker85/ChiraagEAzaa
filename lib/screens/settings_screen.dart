import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../theme.dart';
import '../services/settings_service.dart';
import '../services/push_service.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AnimatedBuilder(
        animation: _s,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            _sectionHeader('Font Size'),
            _settingsCard([
              _sliderRow(
                label: 'Roman / English',
                sub: 'Nouhay · Marsias · Salaam',
                value: _s.ltrFontSize,
                min: 14, max: 26,
                display: '${_s.ltrFontSize.round()}px',
                onChanged: (v) { _s.ltrFontSize = v; _s.save(); },
              ),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              _sliderRow(
                label: 'Arabic / Urdu',
                sub: 'Duas · Ziyaraat · Urdu Marsiye',
                value: _s.rtlFontSize,
                min: 28, max: 56,
                display: '${_s.rtlFontSize.round()}px',
                onChanged: (v) { _s.rtlFontSize = v; _s.save(); },
              ),
            ]),
            _sectionHeader('Spacing'),
            _settingsCard([
              _sliderRow(
                label: 'Paragraph spacing',
                value: _s.paraSpacing,
                min: 0, max: 48,
                display: '${_s.paraSpacing.round()}px',
                onChanged: (v) { _s.paraSpacing = v; _s.save(); },
              ),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              _sliderRow(
                label: 'Line height',
                value: _s.lineHeight,
                min: 1.3, max: 2.5,
                divisions: 12,
                display: _s.lineHeight.toStringAsFixed(1),
                onChanged: (v) {
                  _s.lineHeight = double.parse(v.toStringAsFixed(1));
                  _s.save();
                },
              ),
            ]),
            _sectionHeader('General'),
            _settingsCard([
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
            _sectionHeader('About'),
            _settingsCard([
              _infoRow('Chiraag e Azaa', 'Version 1.0', trailing: const Text('v1.0', style: TextStyle(color: AppTheme.textSecondary))),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              _infoRow('Total Lyrics', 'Nouhay, Marsias, Duas & more', trailing: const Text('5,128', style: TextStyle(color: AppTheme.textSecondary))),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              _infoRow('Offline Mode', 'Works without internet', trailing: const Text('✅', style: TextStyle(fontSize: 20))),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              _pushRow(),
            ]),
            _sectionHeader('Credits'),
            _settingsCard([
              _infoRow('Designed & Developed by', 'Mir Ali', trailing: const Text('💚', style: TextStyle(fontSize: 20))),
              const Divider(height: 1, thickness: 0.5, color: AppTheme.separator),
              const ListTile(
                title: Text('Email'),
                subtitle: Text('gisdevpr31@gmail.com', style: TextStyle(color: AppTheme.textSecondary)),
                trailing: Text('✉️', style: TextStyle(fontSize: 18)),
              ),
            ]),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _pushRow() {
    if (kIsWeb) {
      return const ListTile(
        title: Text('Push Notifications'),
        subtitle: Text(
          'Available in Android and iOS builds',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Icon(Icons.notifications_off_outlined, color: AppTheme.textTertiary),
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
      title: const Text('Push Notifications'),
      subtitle: Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      trailing: _pushStatus == null
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(icon, style: const TextStyle(fontSize: 20)),
      onTap: denied ? null : _togglePush,
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _settingsCard(List<Widget> children) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Column(children: children),
    ),
  );

  Widget _sliderRow({
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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                if (sub != null)
                  Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              ]),
              Text(display, style: const TextStyle(color: AppTheme.green, fontWeight: FontWeight.w600)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.green,
              thumbColor: AppTheme.green,
              inactiveTrackColor: AppTheme.green.withValues(alpha: 0.2),
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

  Widget _infoRow(String label, String sub, {Widget? trailing}) => ListTile(
    title: Text(label, style: const TextStyle(fontSize: 15)),
    subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
    trailing: trailing,
  );
}
