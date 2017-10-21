// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  var app = initFirebaseApp();

  group('DatabaseFunctions', () {
    setUp(() async {
      var ref = app.database().ref('/messages/test/uppercase');
      print('setValue=null');
      await ref.setValue(null).then((_) {
        print('DONE');
      });
      print('setValue=done');
      var data = await ref.once('value');
      print(data.val());
      while (data.val() != null) {
        data = await ref.once('value');
        print(data.val());
      }
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('happy path integration test', () async {
      var ref = app.database().ref('/messages/test/original');
      var value = 'lowercase' + (new DateTime.now().toIso8601String());
      print(value);
      await ref.setValue(value);
      print(value);
      var ucRef = app.database().ref('/messages/test/uppercase');
      var data = await ucRef.once('value');
      print(data.val());
      while (data.val() == null) {
        data = await ucRef.once('value');
        print(data.val());
      }
      expect(data.val(), value.toUpperCase());
    });
  }, timeout: const Timeout(const Duration(seconds: 5)));
}
