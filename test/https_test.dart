// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'dart:convert';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:node_http/node_http.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  App app = initFirebaseApp();
  NodeClient http = new NodeClient(keepAlive: false);
  var baseUrl = env['FIREBASE_HTTP_BASE_URL'] + '/httpsTests';
  var callableUrl = env['FIREBASE_HTTP_BASE_URL'] + '/onCallTests';

  group('$HttpsFunctions', () {
    tearDownAll(() async {
      http.close();
      await app.delete();
    });

    test('get request', () async {
      var response = await http.get('$baseUrl/helloWorld');
      expect(response.statusCode, 200);
      expect(response.body, 'HappyPathTest\n');
    });

    test('save to database', () async {
      var time = new DateTime.now().millisecondsSinceEpoch.toString();
      var response =
          await http.get('$baseUrl/httpsToDatabase?name=Firebase$time');
      expect(response.statusCode, 200);
      expect(response.body, 'httpsToDatabase: ok\n');

      var snapshot = await app
          .database()
          .ref('/tests/httpsToDatabase/original')
          .once<String>('value');
      expect(snapshot.val(), 'FIREBASE$time');
    });

    test('get json body', () async {
      var response = await http.post('$baseUrl/jsonTest',
          headers: {'Content-Type': 'application/json'},
          body: json.encode({"helloJSON": "hi"}));
      expect(response.statusCode, 200);
      expect(response.body, '{"helloJSON":"hi"}');
    });

    test('callable', () async {
      var response = await http.post('$callableUrl',
          headers: {'content-type': 'application/json; charset=utf-8'},
          body: jsonEncode(
            {'data': 'body'},
          ));
      expect(response.statusCode, 200);
      expect(json.decode(response.body), {'result': 'ok'});
    });
  });
}
