// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:node_interop/node.dart';
import 'package:node_interop/util.dart';

final Map<String, String> env =
    new Map<String, String>.from(dartify(process.env));

App initFirebaseApp() {
  if (!env.containsKey('FIREBASE_SERVICE_ACCOUNT_FILEPATH') ||
      !env.containsKey('FIREBASE_DATABASE_URL') ||
      !env.containsKey('FIREBASE_HTTP_BASE_URL')) {
    throw new StateError("Environment variables not set.");
  }

  var admin = FirebaseAdmin.instance;
  return admin.initializeApp(
    new AppOptions(
      credential: admin.certFromPath(env['FIREBASE_SERVICE_ACCOUNT_FILEPATH']),
      databaseURL: env['FIREBASE_DATABASE_URL'],
    ),
  );
}
