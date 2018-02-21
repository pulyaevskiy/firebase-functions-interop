// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

@TestOn('node')
import 'package:test/test.dart';
import 'package:node_http/node_http.dart' as http;
import 'setup_admin.dart';

void main() {
  group('Config', () {
    test('read config', () async {
      var host = env['FIREBASE_HTTP_BASE_URL'];
      var response = await http.get('$host/config');
      expect(response.statusCode, 200);
      final Map result = JSON.decode(response.body);
      expect(result['key'], '123456');
      expect(result['url'], 'https://example.com');
      expect(result['enabled'], 'true');
      expect(result['noSuchKey'], isNull);
    });
  });
}
