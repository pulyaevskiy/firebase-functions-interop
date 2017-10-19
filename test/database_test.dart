// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  group('DatabaseFunctions', () {
    var app = initFirebaseApp();

    setUp(() async {
      var ref = app.database().ref('/messages/test/uppercase');
      await ref.setValue(null);
      var data = await ref.once('value');
      while (data.val() != null) {
        data = await ref.once('value');
      }
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('happy path integration test', () async {
      var ref = app.database().ref('/messages/test/original');
      var value = 'lowercase' + (new DateTime.now().toIso8601String());
      await ref.setValue(value);
      var ucRef = app.database().ref('/messages/test/uppercase');
      var data = await ucRef.once('value');
      while (data.val() == null) {
        data = await ucRef.once('value');
      }
      expect(data.val(), value.toUpperCase());
    });
  }, timeout: const Timeout(const Duration(seconds: 10)));
}
