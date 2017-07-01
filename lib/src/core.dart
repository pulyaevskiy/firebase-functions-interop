import 'dart:js';

import 'bindings.dart';
import 'database.dart';
import 'express.dart';

class FirebaseFunctions {
  final JsFirebaseFunctions _functions;

  FirebaseFunctions._(this._functions);

  factory FirebaseFunctions() {
    return new FirebaseFunctions._(requireFirebaseFunctions());
  }

  Https get https => _https ??= new Https._(_functions.https);
  Https _https;

  Database get database => _database ??= createImpl(_functions.database);
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
