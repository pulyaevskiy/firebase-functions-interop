// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  App app = initFirebaseApp();

  deletePath(String path) async {
    var ref = app.firestore().document(path);

    await ref.delete();
    var snapshot = await ref.get();
    while (snapshot.exists) {
      snapshot = await ref.get();
    }
  }

  group('$Firestore', () {
    setUp(() async {
      await deletePath('tests/uppercase');
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('uppercase', () async {
      var ref = app.firestore().document('tests/uppercase');
      var value = 'lowercase' + (new DateTime.now().toIso8601String());
      var data = new DocumentData();
      data.setString('text', value);
      await ref.setData(data);

      var result = await ref.get();
      while (result.data.getString('uppercase') == null) {
        result = await ref.get();
      }

      expect(result.data.getString('uppercase'), value.toUpperCase());
    }, timeout: const Timeout(const Duration(seconds: 30)));
  });
}
