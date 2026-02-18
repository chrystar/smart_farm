import 'package:flutter_test/flutter_test.dart';
import 'package:smart_farm/core/utils/error_message_helper.dart';

void main() {
  test('Maps network errors to offline message', () {
    final message = ErrorMessageHelper.getUserFriendlyMessage(
      'SocketException: Failed host lookup',
    );

    expect(
      message,
      contains('No internet connection'),
    );
  });

  test('Maps auth errors to server connection message', () {
    final message = ErrorMessageHelper.getUserFriendlyMessage(
      'PostgrestException: JWT expired',
    );

    expect(
      message,
      contains('Unable to connect to server'),
    );
  });

  test('Returns original short non-exception message', () {
    final message = ErrorMessageHelper.getUserFriendlyMessage('Invalid input');
    expect(message, 'Invalid input');
  });
}
