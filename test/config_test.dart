@TestOn('node')
import 'dart:convert';

import 'package:tekartik_http_node/http_universal.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  group('Config', () {
    test('read config', () async {
      var baseUrl = '${env['FIREBASE_HTTP_BASE_URL']!}/httpsTests';
      var client = httpFactoryUniversal.client.newClient();
      var response = await client.get(Uri.parse('$baseUrl/config'));
      expect(response.statusCode, 200);
      final result = json.decode(response.body) as Map;
      expect(result['key'], '123456');
      expect(result['url'], 'https://example.com');
      expect(result['enabled'], 'true');
      expect(result['noSuchKey'], isNull);
    });
  });
}
