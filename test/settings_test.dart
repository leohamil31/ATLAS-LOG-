import 'package:flutter_test/flutter_test.dart';
import 'package:atlas_app/models/models.dart';

void main() {
  test('new settings use the light theme by default', () {
    expect(Settings().darkMode, isFalse);
  });

  test('legacy saved settings migrate to the light theme once', () {
    final settings = Settings.fromJson({'darkMode': true});

    expect(settings.darkMode, isFalse);
    expect(Settings.fromJson(settings.toJson()).darkMode, isFalse);
  });

  test('keeps an explicit theme choice after migration', () {
    final settings = Settings.fromJson({
      'appearanceVersion': 1,
      'darkMode': true,
    });

    expect(settings.darkMode, isTrue);
    expect(Settings.fromJson(settings.toJson()).darkMode, isTrue);
  });
}
