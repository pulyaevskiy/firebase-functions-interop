// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

void main() {
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);
  firebaseFunctions['makeUppercase'] = firebaseFunctions.database
      .ref('/tests/{testId}/original')
      .onWrite(makeUppercase);
}

FutureOr<Null> makeUppercase(DatabaseEvent<String> event) {
  var original = event.data.val();
  var pushId = event.params['testId'];
  print('Uppercasing $original');
  var uppercase = pushId.toString() + ': ' + original.toUpperCase();
  return event.data.ref.parent.child('uppercase').setValue(uppercase);
}

Future helloWorld(HttpRequest request) async {
  try {
    String name = request.requestedUri.queryParameters['name'];
    bool conf = request.requestedUri.queryParameters.containsKey('config');
    if (conf) {
      var config = firebaseFunctions.config;
      var serviceKey = config.get('someservice.key');
      var serviceUrl = config.get('someservice.url');
      request.response.writeln('FirebaseConfig: $serviceKey, $serviceUrl');
    } else if (name != null) {
      var appOptions = firebaseFunctions.config.firebase;
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp(
          credential: appOptions.credential,
          databaseURL: appOptions.databaseURL);
      var database = app.database();
      await database
          .ref('/tests/httpsToDatabase/original')
          .setValue(name.toUpperCase());
      request.response.writeln('HTTPS-to-Database: ${name.toUpperCase()}');
    } else {
      request.response.writeln('HappyPathTest');
    }
  } finally {
    request.response.close();
  }
}
