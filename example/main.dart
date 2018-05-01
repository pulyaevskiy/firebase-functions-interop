// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  /// You can export a function by setting a key on global [functions]
  /// object.
  ///
  /// For HTTPS functions the key is also a URL path prefix, so in below
  /// example `helloWorld` function will be available at `/helloWorld`
  /// URL path and it will also handle all paths under this prefix, e.g.
  /// `/helloWorld/any/number/of/sections`.
  functions['helloWorld'] = FirebaseFunctions.https.onRequest(helloWorld);
  functions['makeUppercase'] = FirebaseFunctions.database
      .ref('/tests/{testId}/original')
      .onWrite(makeUppercase);
  functions['makeNamesUppercase'] = FirebaseFunctions.firestore
      .document('/users/{userId}')
      .onWrite(makeNamesUppercase);
  functions['logPubsub'] =
      FirebaseFunctions.pubsub.topic('my-topic').onPublish(logPubsub);
  functions['logStorage'] =
      FirebaseFunctions.storage.object().onFinalize(logStorage);
  functions['logAuth'] = FirebaseFunctions.auth.user().onCreate(logAuth);
}

/// Example Realtime Database function.
FutureOr<void> makeUppercase(
    Change<DataSnapshot<String>> change, EventContext context) {
  final DataSnapshot<String> snapshot = change.after;
  var original = snapshot.val();
  var pushId = context.params['testId'];
  print('Uppercasing $original');
  var uppercase = pushId.toString() + ': ' + original.toUpperCase();
  return snapshot.ref.parent.child('uppercase').setValue(uppercase);
}

/// Example Firestore
FutureOr<void> makeNamesUppercase(
    Change<DocumentSnapshot> change, EventContext context) {
  // Since this is an update of the same document we must guard against
  // infinite cycle of this function writing, reading and writing again.
  final snapshot = change.after;
  if (snapshot.data.getString("uppercasedName") == null) {
    var original = snapshot.data.getString("name");
    print('Uppercasing $original');

    UpdateData newData = new UpdateData();
    newData.setString("uppercasedName", original);

    return snapshot.reference.updateData(newData);
  }
  return null;
}

/// Example Pubsub
void logPubsub(Message message, EventContext context) {
  print(message.json["name"]);
}

/// Example Storage
void logStorage(ObjectMetadata data, EventContext contet) {
  print(data.name);
}

/// Example Auth
void logAuth(UserRecord data, EventContext context) {
  print(data.email);
}

/// Example HTTPS function.
Future<void> helloWorld(ExpressHttpRequest request) async {
  try {
    /// If there are any config parameters we can access them as follows:
    var config = FirebaseFunctions.config;
    var serviceKey = config.get('someservice.key');
    var serviceUrl = config.get('someservice.url');
    // Don't do this on a real project:
    print('Service key: $serviceKey, service URL: $serviceUrl');

    /// The provided [request] is fully compatible with "dart:io" `HttpRequest`
    /// including the fact that it's a valid Dart `Stream`.
    /// Note though that Firebase uses body-parser expressjs middleware which
    /// decodes request body for some common content-types (json included).
    /// In such cases use `request.body` which contains decoded body.
    String name = request.requestedUri.queryParameters['name'];
    if (name != null) {
      // We can also write to Realtime Database right here:
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp();
      var database = app.database();
      await database.ref('/tests/some-path').setValue(name);
    }
    request.response.writeln('Hello world');
  } finally {
    request.response.close();
  }
}
