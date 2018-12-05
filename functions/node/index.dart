// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['httpsTests'] = functions.https.onRequest(httpsTests);
  functions['onCallTests'] = functions.https.onCall(onCallTests);

  functions['makeUppercase'] =
      functions.database.ref('/tests/{testId}/original').onWrite(makeUppercase);

  functions['firestoreUppercase'] = functions.firestore
      .document('tests/uppercase')
      .onWrite(firestoreUppercase);

  functions['pubsubToDatabase'] =
      functions.pubsub.topic('testTopic').onPublish(pubsubToDatabase);
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
    case '/httpsToFirestore':
      return httpsToFirestore(request);
    default:
      request.response.close();
      return null;
  }
}

FutureOr onCallTests(dynamic data, CallableContext context) {
  return 'ok';
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
    var config = functions.config;
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
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp();
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

FutureOr<void> httpsToFirestore(ExpressHttpRequest request) async {
  try {
    String name = request.requestedUri.queryParameters['name'];
    if (name != null) {
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp();
      var firestore = app.firestore();
      var doc = new DocumentData();
      doc.setGeoPoint('location', new GeoPoint(23.03, 19.84));
      doc.setString('name', name);
      await firestore.document('/tests/httpsToFirestore').setData(doc);
      request.response.writeln('httpsToFirestore: ok');
    }
  } catch (e) {
    request.response.statusCode = 500;
    request.response.write(e.toString());
  } finally {
    request.response.close();
    return null;
  }
}

FutureOr<void> makeUppercase(
    Change<DataSnapshot<String>> change, EventContext context) {
  var data = change.after;
  var original = data.val();
  var pushId = context.params['testId'];
  print('Uppercasing $original');
  var uppercase = pushId.toString() + ': ' + original.toUpperCase();
  return data.ref.parent.child('uppercase').setValue(uppercase);
}

FutureOr<void> firestoreUppercase(
    Change<DocumentSnapshot> change, EventContext context) {
  if (!change.after.exists) {
    print('Skipping uppercase because document was deleted.');
    return null;
  }
  var data = change.after.data;
  if (data.getString('uppercase') != null) {
    // This document has been uppercased already, return to avoid infinite loop.
    print('Skipping uppercase to avoid infinite loop.');
    return null;
  }
  var original = data.getString('text');
  print('Uppercasing $original');
  var update = new UpdateData();
  update.setString('uppercase', original.toUpperCase());
  return change.after.reference.updateData(update);
}

FutureOr<void> pubsubToDatabase(Message message, EventContext context) {
  var data = new Map<String, String>.from(message.json);
  var payload = data['payload'];
  var admin = FirebaseAdmin.instance;
  var app = admin.initializeApp();
  var database = app.database();
  return database.ref('/tests/pubsubToDatabase').setValue(payload);
}
