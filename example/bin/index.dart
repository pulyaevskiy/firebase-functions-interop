library my_functions;

import 'dart:async';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  // Example HTTPS cloud function which responds with "Hello World".
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);

  // Example Realtime Database cloud function from the Getting Started tutorial:
  // https://firebase.google.com/docs/functions/get-started
  firebaseFunctions['makeUppercase'] = firebaseFunctions.database
      .ref('/messages/{pushId}/original')
      .onWrite(makeUppercase);
}

void helloWorld(HttpRequest request) {
  String name = request.requestedUri.queryParameters['name'];
  if (name != null) {
    request.response
        .writeln('Hello to you $name from Dart Firebase Functions interop');
  } else {
    request.response.writeln('Hello from Dart Firebase Functions interop');
  }
  request.response.close();
}

FutureOr<Null> makeUppercase(event) {
  String original = event.data.val();
  print('Uppercasing $original');
  String uppercase = original.toUpperCase();
  return event.data.ref.parent.child('uppercase').setValue(uppercase);
}
