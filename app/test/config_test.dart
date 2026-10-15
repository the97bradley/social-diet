import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/config.dart';

void main() {
  test('defaults create-account to the Vercel API', () {
    expect(
      AppConfig.apiBaseUrl,
      'https://social-diet-denver-porchfest1.vercel.app',
    );
  });
}
