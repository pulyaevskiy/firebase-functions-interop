// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js';

import 'package:node_interop/node_interop.dart';
import 'package:node_interop/http.dart';
import 'package:firebase_admin_interop/js.dart' as admin;
import 'package:expressjs_interop/expressjs_interop.dart' as express;

import 'bindings.dart' as js;
import 'database.dart';

export 'bindings.dart' show CloudFunction;

final FirebaseFunctions firebaseFunctions = new FirebaseFunctions._();

/// Global namespace from which all the Cloud Functions are accessed.
class FirebaseFunctions {
  final Https https = new Https._();
  final Database database = createImpl();
  final Config config = new Config();

  FirebaseFunctions._();

  void export(String name, dynamic function) {
    node.export(name, function);
  }

  operator []=(String key, dynamic function) {
    assert(function is js.HttpsFunction || function is js.CloudFunction);
    node.export(key, function);
  }
}

/// Provides access to Firebase environment configuration.
///
/// See also:
/// - https://firebase.google.com/docs/functions/config-env
class Config {
  js.Config _config;
  js.Config get nativeInstance => _config ??= js.config();

  /// Returns configuration value specified by it's [key].
  ///
  /// This method expects keys to be fully qualified (namespaced), e.g.
  /// `some_service.client_secret` or `some_service.url`.
  /// This is different from native JS implementation where namespaced
  /// keys are broken into nested JS object structure, e.g.
  /// `functions.config().some_service.client_secret`.
  dynamic get(String key) {
    var data = dartify(nativeInstance);
    var parts = key.split('.');
    var value;
    for (var subKey in parts) {
      if (data is! Map) return null;
      value = data[subKey];
      if (value == null) break;
      data = value;
    }
    return value;
  }

  /// Firebase-specific configuration which can be used to initialize
  /// Firebase Admin SDK.
  ///
  /// This is a shortcut for calling `get('firebase')`.
  admin.AppOptions get firebase => get('firebase');
}

typedef void HttpRequestListener(
    express.Request request, express.Response response);

class Https {
  Https._();

  /// Creates HTTPS function from [handler].
  js.HttpsFunction onRequest(HttpRequestListener handler) {
    return js.onRequest(allowInterop(handler));
  }
}

HttpRequestListener translateHandler(void ioHandler(HttpRequest request)) {
  return (IncomingMessage req, ServerResponse res) {
    ioHandler(new HttpRequest(req, res));
  };
}
