// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Interop library for Firebase Functions NodeJS SDK.
library firebase_functions_interop;

import 'dart:async';
import 'dart:js';
import 'package:node_interop/util.dart';

import 'src/bindings.dart';
import 'src/express.dart';

export 'package:node_interop/node_interop.dart' show exports;

export 'src/bindings.dart' show JsCloudFunction;
export 'src/express.dart' show Request, Response;

class FirebaseFunctions implements JsFirebaseFunctions {
  final JsFirebaseFunctions _functions;

  FirebaseFunctions._(this._functions);

  factory FirebaseFunctions() {
    return new FirebaseFunctions._(requireFirebaseFunctions());
  }

  @override
  Https get https => _https ??= new Https._(_functions.https);
  Https _https;

  @override
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

class Database implements JsDatabase {
  final JsDatabase _inner;

  Database._(this._inner);

  @override
  RefBuilder ref(String path) {
    var jsRef = _inner.ref(path);
    return new RefBuilder._(jsRef);
  }
}

class RefBuilder implements JsRefBuilder {
  final JsRefBuilder _inner;

  RefBuilder._(this._inner);

  @override
  JsCloudFunction onWrite(dynamic handler(Event event)) {
    dynamic wrapper(JsEvent event) {
      var dartEvent = new Event._(
        data: new DeltaSnapshot(event.data),
        eventId: event.eventId,
        eventType: event.eventType,
        params: jsObjectToMap(event.params),
        resource: event.resource,
        timestamp: DateTime.parse(event.timestamp),
      );
      var result = handler(dartEvent);
    }

    var jsWrapper = allowInterop(wrapper);

    return _inner.onWrite(jsWrapper);
  }
}

class Event implements JsEvent {
  final dynamic data;
  final String eventId;
  final String eventType;
  final Map<String, String> params;
  final String resource;
  final DateTime timestamp;

  Event._({
    this.data,
    this.eventId,
    this.eventType,
    this.params,
    this.resource,
    this.timestamp,
  });
}

class DeltaSnapshot implements JsDeltaSnapshot {
  final JsDeltaSnapshot _inner;

  DeltaSnapshot(this._inner);

  @override
  Reference get adminRef => new Reference._(_inner.adminRef);

  @override
  bool changed() => _inner.changed();

  @override
  DeltaSnapshot child(String path) => new DeltaSnapshot(_inner.child(path));

  @override
  DeltaSnapshot get current => new DeltaSnapshot(_inner.current);

  @override
  bool exists() => _inner.exists();

  @override
  bool hasChild(String path) => _inner.hasChild(path);

  @override
  bool hasChildren() => _inner.hasChildren();

  @override
  String get key => _inner.key;

  @override
  int numChildren() => _inner.numChildren();

  @override
  DeltaSnapshot get previous => new DeltaSnapshot(_inner.previous);

  @override
  Reference get ref => new Reference._(_inner.ref);

  @override
  val() => jsObjectToMap(_inner.val());
}

class Reference implements JsReference {
  final JsReference _inner;

  Reference._(this._inner);

  @override
  Reference child(String path) => new Reference._(_inner.child(path));

  @override
  Reference get parent => new Reference._(_inner.parent);

  @override
  Future<Null> set(value, void onComplete(error)) {
    var promise = _inner.set(value, null); // TODO: handle onComplete()
    var completer = new Completer<Null>();
    if (promise is Promise) {
      promise.then((value) {
        completer.complete(value);
      }, (error) {
        completer.completeError(error);
      });
    } else {
      completer.complete();
    }
    return completer.future;
  }
}
