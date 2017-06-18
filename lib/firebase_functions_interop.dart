// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Interop library for Firebase Functions NodeJS SDK.
library firebase_functions_interop;

import 'dart:async';
import 'dart:js';

import 'package:node_interop/node_interop.dart';

import 'src/bindings.dart';
import 'src/express.dart';

export 'package:node_interop/node_interop.dart' show exports;

export 'src/bindings.dart' show JsCloudFunction;
export 'src/express.dart' show Request, Response;

part 'src/database.dart';

class FirebaseFunctions {
  final JsFirebaseFunctions _functions;

  FirebaseFunctions._(this._functions);

  factory FirebaseFunctions() {
    return new FirebaseFunctions._(requireFirebaseFunctions());
  }

  Https get https => _https ??= new Https._(_functions.https);
  Https _https;

  Database get database => _database ??= new Database._(_functions.database);
  Database _database;
}

typedef void RequestHandler(Request request, Response response);

class Https implements JsHttps {
  final JsHttps _inner;
  Https._(this._inner);

  JsCloudFunction onRequest(RequestHandler handler) {
    void wrapper(JsRequest jsReq, JsResponse jsRes) {
      var request = new Request(jsReq);
      var response = new Response(jsRes);
      handler(request, response);
    }

    var jsWrapper = allowInterop(wrapper);
    return _inner.onRequest(jsWrapper);
  }
}
