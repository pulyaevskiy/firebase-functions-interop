library my_functions;

import 'dart:async';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

void main() {
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);
  firebaseFunctions['makeUppercase'] = firebaseFunctions.database
      .ref('/messages/{pushId}/original')
      .onWrite(makeUppercase);
}

FutureOr<Null> makeUppercase(event) {
  String original = event.data.val();
  print('Uppercasing $original');
  String uppercase = original.toUpperCase();
  return event.data.ref.parent.child('uppercase').set(uppercase);
}

Future helloWorld(HttpRequest request) async {
  var config = firebaseFunctions.config;
  var serviceKey = config.get('someservice.key');
  var serviceUrl = config.get('someservice.url');
  String name = request.requestedUri.queryParameters['name'];
  if (name != null) {
    var config = firebaseFunctions.config.firebase;
    var admin = FirebaseAdmin.instance;
    var app = admin.initializeApp(
        credential: config.credential, databaseURL: config.databaseURL);
    var database = app.database();
    await database
        .ref('/hello-world-name-uppercase')
        .setValue(name.toUpperCase());
    request.response.writeln(
        'Hello to you ${name.toUpperCase()} from Dart Firebase Functions interop');
  } else {
    request.response.writeln(
        'Hello  from Dart Firebase Functions interop. Here is my secret config: $serviceKey, $serviceUrl');
  }
  request.response.close();
}
