import 'package:flutter_test/flutter_test.dart';
import 'package:chiraag_e_azaa/services/push_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localized Notification Tests', () {
    test('Arabic (ar) localization returns Arabic title, body and channels', () {
      final content = PushNotificationService.getLocalizedContent('ar');
      expect(content.title, contains('چراغ عزا'));
      expect(content.body, contains('السلام عليك يا أبا عبد الله'));
      expect(content.channelName, contains('أذكار وأدعية'));
      expect(content.testTitle, contains('إشعار تجريبي'));
    });

    test('Urdu (ur) localization returns Urdu title, body and channels', () {
      final content = PushNotificationService.getLocalizedContent('ur');
      expect(content.title, contains('چراغِ عزا'));
      expect(content.body, contains('السلام علیک یا ابا عبد اللہ'));
      expect(content.channelName, contains('دعائیں و زیارات'));
      expect(content.testTitle, contains('آزمائشی اطلاع'));
    });

    test('English / default localization returns English title and body', () {
      final content = PushNotificationService.getLocalizedContent('en');
      expect(content.title, contains('Chiraag e Azaa'));
      expect(content.body, contains('Aba Abdillah'));
      expect(content.channelName, contains('Daily Recitations'));
      expect(content.testTitle, contains('Test Notification'));
    });

    test('Device language detection returns a non-empty string and display badge', () {
      final code = PushNotificationService.getDeviceLanguageCode();
      final display = PushNotificationService.getDeviceLanguageDisplay();
      expect(code, isNotEmpty);
      expect(display, isNotEmpty);
    });
  });
}
