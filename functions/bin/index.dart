library my_functions;

import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  var httpsFunc = firebaseFunctions.https.onRequest(helloWorld);
  exportFunction('helloWorld', httpsFunc);

  var dbFunc = firebaseFunctions.database
      .ref('/messages/{pushId}/original')
      .onWrite((event) {
    String original = event.data.val();
    print('Uppercasing $original');
    String uppercase = original.toUpperCase();
    return event.data.ref.parent.child('uppercase').set(uppercase);
  });
  exportFunction('makeUppercase', dbFunc);
}

void helloWorld(request, response) {
  var config = firebaseFunctions.config();
  var serviceKey = config.get('someservice.key');
  var serviceUrl = config.get('someservice.url');
  String name = request.query['name'];
  if (name != null) {
    response.send('Hello to you $name from Dart Firebase Functions interop');
  } else {
    response.send(
        'Hello  from Dart Firebase Functions interop. Here is my secret config: $serviceKey, $serviceUrl');
  }
}
