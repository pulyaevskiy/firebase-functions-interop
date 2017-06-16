library my_functions;

import 'package:node_interop/node_interop.dart';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  var functions = new FirebaseFunctions();
  var httpsFunc = functions.https.onRequest((request, response) {
    String name = request.query['name'];
    if (name != null) {
      response.send('Hello to you $name from Dart Firebase Functions interop');
    } else {
      response.send('Hello from Dart Firebase Functions interop');
    }
  });
  exports.setProperty('helloWorld', httpsFunc);
}
