import 'dart:js';

import 'package:node_interop/node_interop.dart';

import 'bindings.dart' as js;
import 'database.dart';

export 'bindings.dart' show CloudFunction;

final FirebaseFunctions firebaseFunctions =
    new FirebaseFunctions._(require('firebase-functions'));

/// Global namespace from which all the Cloud Functions are accessed.
class FirebaseFunctions {
  final js.FirebaseFunctions _inner;

  FirebaseFunctions._(this._inner);

  @Deprecated("Use the top-level `firebaseFunctions` variable instead.")
  factory FirebaseFunctions() => firebaseFunctions;

  /// Namespace for HTTPS functions.
  Https get https => _https ??= new Https._(_inner.https);
  Https _https;

  /// Namespace for Realtime Database functions.
  Database get database => _database ??= createImpl(_inner.database);
  Database _database;

  /// Returns environment configuration object.
  Config config() => _config ??= new Config(_inner.config());
  Config _config;
}

/// Provides access to Firebase environment configuration.
///
/// See also:
/// - https://firebase.google.com/docs/functions/config-env
class Config {
  final _inner;

  Config(this._inner);

  /// Returns configuration value specified by it's [key].
  ///
  /// This method expects keys to be fully qualified (namespaced), e.g.
  /// `some_service.client_secret` or `some_service.url`.
  /// This is different from native JS implementation where namespaced
  /// keys are broken into nested JS object structure, e.g.
  /// `functions.config().some_service.client_secret`.
  dynamic get(String key) {
    var data = dartify(_inner);
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
  Map<String, dynamic> get firebase => get('firebase');
}

class Https {
  final js.Https _inner;
  Https._(this._inner);

  /// Creates HTTPS function from [handler].
  ///
  ///
  js.CloudFunction onRequest(HttpRequestListener handler) {
    return _inner.onRequest(allowInterop(handler));
  }
}
