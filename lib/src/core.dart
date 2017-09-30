import 'dart:js';

import 'package:node_interop/node_interop.dart';

import 'bindings.dart';
import 'database.dart';
import 'express.dart';

final FirebaseFunctions firebaseFunctions =
    new FirebaseFunctions._(require('firebase-functions'));

/// Global namespace from which all the Cloud Functions are accessed.
class FirebaseFunctions {
  final JsFirebaseFunctions _functions;

  FirebaseFunctions._(this._functions);

  @Deprecated("Use the top-level `firebaseFunctions` variable instead.")
  factory FirebaseFunctions() => firebaseFunctions;

  /// Namespace for HTTPS functions.
  Https get https => _https ??= new Https._(_functions.https);
  Https _https;

  /// Namespace for Realtime Database functions.
  Database get database => _database ??= createImpl(_functions.database);
  Database _database;

  /// Returns environment configuration object.
  Config config() => _config ??= new Config(_functions.config());
  Config _config;
}

/// Provides access to Firebase environment configuration.
///
/// See also:
/// - https://firebase.google.com/docs/functions/config-env
class Config {
  final _config;

  Config(this._config);

  /// Returns configuration value specified by it's [key].
  ///
  /// This method expects keys to be fully qualified (namespaced), e.g.
  /// `some_service.client_secret` or `some_service.url`.
  /// This is different from native JS implementation where namespaced
  /// keys are broken into nested JS object structure, e.g.
  /// `functions.config().some_service.client_secret`.
  dynamic get(String key) {
    var data = dartify(_config);
    var parts = key.split('.');
    var value;
    for (var subKey in parts) {
      if (data is! Map) return null;
      value = dartify(data[subKey]);
      if (value == null) break;
      data = value;
    }
    return value;
  }

  /// Firebase-specific configuration which can be used to initialize
  /// Firebase Admin SDK.
  ///
  /// This is a shortcut for calling `get('firebase')`.
  Map<String, dynamic> get firebase => get('firebase');
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
