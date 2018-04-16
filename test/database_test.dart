// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  App app = initFirebaseApp();

  deletePath(String path) async {
    var ref = app.database().ref(path);

    await ref.setValue(null);
    var data = await ref.once('value');
    while (data.val() != null) {
      data = await ref.once('value');
    }
  }

  group('Database', () {
    setUp(() async {
      await deletePath('/tests/happyPath/uppercase');
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('happy path integration test', () async {
      var ref = app.database().ref('/tests/happyPath/original');
      var value = 'lowercase' + (new DateTime.now().toIso8601String());
      await ref.setValue(value);
      var ucRef = app.database().ref('/tests/happyPath/uppercase');
      var data = await ucRef.once('value');
      while (data.val() == null) {
        data = await ucRef.once('value');
      }
      var expected = 'happyPath: ' + value.toUpperCase();
      expect(data.val(), expected);
    }, timeout: const Timeout(const Duration(seconds: 10)));
  });
}
