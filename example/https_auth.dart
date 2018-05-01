// Copyright (c) 2018, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

void main() {
  functions['secured'] = FirebaseFunctions.https.onRequest(secured);
}

/// Example HTTPS function which requires Firebase authenticated user.
///
/// We use Firebase Admin SDK to verify user's ID token which must be present
/// in the request's "Authorization" header as a Bearer token.
///
/// Based on this sample:
/// - https://github.com/firebase/functions-samples/tree/master/authorized-https-endpoint

Future secured(ExpressHttpRequest request) async {
  try {
    String auth = request.headers.value('authorization');
    if (auth != null && auth.startsWith('Bearer ')) {
      print('Authorization header found.');
      var admin = FirebaseAdmin.instance;
      var app = admin.initializeApp();

      String idToken = auth.split(' ').last;
      DecodedIdToken decodedToken =
          await app.auth().verifyIdToken(idToken).catchError((error) => null);
      if (decodedToken == null) {
        print('Invalid or expired authorization token provided.');
        request.response.statusCode = 403;
        request.response.write('Unauthorized');
      } else {
        /// Authorization successful.
        /// Use Admin SDK to fetch the authorized user's record:
        final user = await app.auth().getUser(decodedToken.uid);
        request.response.statusCode = 200;
        request.response.write('Hello ${user.displayName}!');
      }
    } else {
      print('No authorization header found.');
      request.response.statusCode = 403;
      request.response.write('Unauthorized');
    }
  } finally {
    request.response.close();
  }
}
