import 'package:flutter_test/flutter_test.dart';
import 'package:social_diet/widgets.dart';

void main() {
  test('maps auth email rate-limit exceptions', () {
    expect(
      errorMessage('email rate limit exceeded'),
      'Too many confirmation emails just now. Wait a few minutes and try again, or sign in if the account already exists.',
    );
    expect(
      errorMessage(
        Exception(
          'AuthApiException: email rate limit exceeded, statusCode: 429, code: over_email_send_rate_limit',
        ),
      ),
      'Too many confirmation emails just now. Wait a few minutes and try again, or sign in if the account already exists.',
    );
  });

  test('maps already-registered signup', () {
    expect(
      errorMessage(Exception('AuthApiException: User already registered')),
      'That email already has an account. Sign in instead.',
    );
  });

  test('leaves other errors alone', () {
    expect(errorMessage(Exception('Username must be 3-24 letters')),
        'Exception: Username must be 3-24 letters');
  });
}
