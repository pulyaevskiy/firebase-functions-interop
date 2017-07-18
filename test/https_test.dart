@TestOn('vm')
import 'package:test/test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('HTTPS', () {
    test('happy path integration test', () async {
      var host = 'https://us-central1-fir-functions-interop.cloudfunctions.net';
      var response = await http.get('$host/helloWorld');
      expect(response.body, 'Hello from Dart Firebase Functions interop');
    });
  });
}
