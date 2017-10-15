// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@JS()
library setup;

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:js/js.dart';
import 'package:node_interop/node_interop.dart';
import 'package:node_interop/test.dart';

final Map<String, String> env = node.platform.environment;

App initFirebaseApp() {
  if (!env.containsKey('FIREBASE_SERVICE_ACCOUNT_FILEPATH') ||
      !env.containsKey('FIREBASE_DATABASE_URL') ||
      !env.containsKey('FIREBASE_HTTP_BASE_URL')) {
    throw new StateError("Environment variables not set.");
  }
  installNodeModules({"firebase-admin": "~4.2.1"});

  var admin = new FirebaseAdmin();
  return admin.initializeApp(
    credential:
        admin.credential.certFromPath(env['FIREBASE_SERVICE_ACCOUNT_FILEPATH']),
    databaseURL: env['FIREBASE_DATABASE_URL'],
  );
}
