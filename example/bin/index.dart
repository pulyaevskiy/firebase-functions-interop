library my_functions;

import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  // Example HTTPS cloud function which responds with "Hello World".
  var httpsFunc = firebaseFunctions.https.onRequest((request, response) {
    String name = request.query['name'];
    if (name != null) {
      response.send('Hello to you $name from Dart Firebase Functions interop');
    } else {
      response.send('Hello from Dart Firebase Functions interop');
    }
  });
  exports.setProperty('helloWorld', httpsFunc);

  // Example Realtime Database cloud function from the Getting Started tutorial:
  // https://firebase.google.com/docs/functions/get-started
  var dbFunc = firebaseFunctions.database
      .ref('/messages/{pushId}/original')
      .onWrite((event) {
    String original = event.data.val();
    print('Uppercasing $original');
    String uppercase = original.toUpperCase();
    return event.data.ref.parent.child('uppercase').set(uppercase);
  });
  exports.setProperty('makeUppercase', dbFunc);
}
