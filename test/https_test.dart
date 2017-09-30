@TestOn('vm')
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('HTTPS', () {
    test('happy path integration test', () async {
      var host = Platform.environment['FIREBASE_HTTP_BASE_URL'];
      var response = await http.get('$host/helloWorld');
      expect(
          response.body,
          'Hello from Dart Firebase Functions interop. '
          'Here is my secret config: 123456, https://example.com');
    });
  });
}
