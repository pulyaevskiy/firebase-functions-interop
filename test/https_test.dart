// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'dart:convert';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:node_http/node_http.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  App app = initFirebaseApp();
  NodeClient http = new NodeClient(keepAlive: false);

  group('HTTPS', () {
    tearDownAll(() async {
      http.close();
      await app.delete();
    });

    test('get request', () async {
      var host = env['FIREBASE_HTTP_BASE_URL'];
      var response = await http.get('$host/helloWorld');
      expect(response.statusCode, 200);
      expect(response.body, 'HappyPathTest\n');
    });

    test('save to database', () async {
      var host = env['FIREBASE_HTTP_BASE_URL'];
      var time = new DateTime.now().millisecondsSinceEpoch.toString();
      var response = await http.get('$host/httpsToDatabase?name=Firebase$time');
      expect(response.statusCode, 200);
      expect(response.body, 'httpsToDatabase: ok\n');

      var snapshot = await app
          .database()
          .ref('/tests/httpsToDatabase/original')
          .once<String>('value');
      expect(snapshot.val(), 'FIREBASE$time');
    });

    test('get json body', () async {
      var host = env['FIREBASE_HTTP_BASE_URL'];
      var response = await http.post('$host/jsonTest',
          headers: {'Content-Type': 'application/json'},
          body: JSON.encode({"helloJSON": "hi"}));
      expect(response.statusCode, 200);
      expect(response.body, '{"helloJSON":"hi"}');
    });
  });
}
