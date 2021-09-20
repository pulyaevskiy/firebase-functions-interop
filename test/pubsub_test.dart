// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@TestOn('node')
import 'dart:async';
import 'dart:js';

import 'package:node_interop/child_process.dart';
import 'package:test/test.dart';

import 'setup_admin.dart';

void main() {
  var app = initFirebaseApp();

  group('Pubsub', () {
    tearDownAll(() async {
      await app!.delete();
    });

    test('save to database', () async {
      var payload = DateTime.now().toUtc().toIso8601String();
      var command =
          'gcloud -q beta pubsub topics publish testTopic --message \'{"payload":"$payload"}\'';
      var exitCode = await exec(command);
      expect(exitCode, 0);

      var snapshot = await app!
          .database()
          .ref('/tests/pubsubToDatabase')
          .once<String>('value');
      while (snapshot.val() != payload) {
        snapshot = await app
            .database()
            .ref('/tests/pubsubToDatabase')
            .once<String>('value');
      }
      expect(snapshot.val(), payload);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}

Future<int> exec(String command) {
  var completer = Completer<int>();
  childProcess.exec(command, ExecOptions(),
      allowInterop((dynamic error, stdout, stderr) {
    // ignore: avoid_dynamic_calls
    var result = (error == null) ? 0 : error!.code as int;
    print(stdout);
    if (error != null) {
      print(error);
      print(stderr);
    }
    completer.complete(result);
  }));
  return completer.future;
}
