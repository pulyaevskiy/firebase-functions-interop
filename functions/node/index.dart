// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

void main() {
  functions['httpsTests'] = FirebaseFunctions.https.onRequest(httpsTests);

  functions['makeUppercase'] = FirebaseFunctions.database
      .ref('/tests/{testId}/original')
      .onWrite(makeUppercase);
  final ref = FirebaseFunctions.database.ref('/onCreateUpdateDelete/value');
  functions['onCreateTrigger'] = ref.onCreate(handleCreateUpdateDelete);
  functions['onUpdateTrigger'] = ref.onUpdate(handleCreateUpdateDelete);
  functions['onDeleteTrigger'] = ref.onDelete(handleCreateUpdateDelete);

  functions['pubsubToDatabase'] =
      FirebaseFunctions.pubsub.topic('testTopic').onPublish(pubsubToDatabase);
}

FutureOr<void> httpsTests(ExpressHttpRequest request) {
  print(request.uri.path);
  switch (request.uri.path) {
    case '/jsonTest':
      return jsonTest(request);
    case '/date':
      return date(request);
    case '/helloWorld':
      return helloWorld(request);
    case '/config':
      return config(request);
    case '/httpsToDatabase':
      return httpsToDatabase(request);
    default:
      request.response.close();
      return null;
  }
}

jsonTest(ExpressHttpRequest request) {
  final Map<String, dynamic> data = request.body;
  request.response.write(json.encode(data));
  request.response.close();
}

date(ExpressHttpRequest request) {
  DateTime now = new DateTime.now().toUtc();
  request.response.writeln(now.toIso8601String());
  request.response.close();
}

helloWorld(ExpressHttpRequest request) {
  try {
    request.response.writeln('HappyPathTest');
  } finally {
    request.response.close();
  }
}

config(ExpressHttpRequest request) {
  try {
    var config = FirebaseFunctions.config;
    Map body = {
      'key': config.get('someservice.key'),
      'url': config.get('someservice.url'),
      'enabled': config.get('someservice.enabled'),
      'noSuchKey': config.get('no.such.key'),
    };
    request.response.writeln(json.encode(body));
  } finally {
    request.response.close();
  }
}

FutureOr<void> httpsToDatabase(ExpressHttpRequest request) async {
  try {
    String name = request.requestedUri.queryParameters['name'];
    if (name != null) {
      var appOptions = FirebaseFunctions.config.firebase;
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp(appOptions);
      var database = app.database();
      await database
          .ref('/tests/httpsToDatabase/original')
          .setValue(name.toUpperCase());
      request.response.writeln('httpsToDatabase: ok');
    }
  } catch (e) {
    request.response.statusCode = 500;
    request.response.write(e.toString());
  } finally {
    request.response.close();
    return null;
  }
}

FutureOr<void> makeUppercase(DatabaseEvent<String> event) {
  var original = event.data.val();
  var pushId = event.params['testId'];
  print('Uppercasing $original');
  var uppercase = pushId.toString() + ': ' + original.toUpperCase();
  return event.data.ref.parent.child('uppercase').setValue(uppercase);
}

FutureOr<Null> handleCreateUpdateDelete(DatabaseEvent<String> event) {
  final eventType = event.eventType;
  return event.data.ref.parent.child('lastEventType').setValue(eventType);
}

FutureOr<void> pubsubToDatabase(PubsubEvent event) {
  var data = new Map<String, String>.from(event.data.json);
  var payload = data['payload'];
  var appOptions = FirebaseFunctions.config.firebase;
  var admin = FirebaseAdmin.instance;
  var app = admin.initializeApp(appOptions);
  var database = app.database();
  return database.ref('/tests/pubsubToDatabase').setValue(payload);
}
