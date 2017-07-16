@TestOn('vm')
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('HTTPS', () {
    test('happy path integration test', () async {
      var host = new String.fromEnvironment('FIREBASE_HTTPS_HOST');
      var response = await http.get('$host/helloWorld');
      expect(response.body, 'Hello from Dart Firebase Functions interop');
    });
  });
}
