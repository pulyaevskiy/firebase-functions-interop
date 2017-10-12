import 'dart:async';
import 'dart:js' as js;
import 'package:node_interop/node_interop.dart';

import 'bindings.dart' as js;

Database createImpl(js.Database source) => new Database._(source);

class Database {
  final js.Database _inner;

  Database._(this._inner);

  RefBuilder ref(String path) => new RefBuilder._(_inner.ref(path));

  // TODO: maybe this is not really needed and we can settle with integration testing?
  // JsDeltaSnapshot createSnapshot() {
  //   var obj = js.context['Object']
  //       .callMethod('create', [_inner.DeltaSnapshot.prototype]);
  //   _inner.DeltaSnapshot.apply(obj, [null, null, null, 'foo', null]);
  //   return obj;
  // }
}

class RefBuilder {
  final js.RefBuilder _inner;

  RefBuilder._(this._inner);

  js.CloudFunction onWrite(FutureOr<Null> handler(DatabaseEvent event)) {
    dynamic wrapper(js.JsEvent event) {
      var dartEvent = new DatabaseEvent(
        data: new DeltaSnapshot._(event.data),
        eventId: event.eventId,
        eventType: event.eventType,
        params: dartify(event.params),
        resource: event.resource,
        timestamp: DateTime.parse(event.timestamp),
      );
      var result = handler(dartEvent);
      if (result is Future) {
        return futureToJsPromise(result);
      }
      return null;
    }

    var jsWrapper = js.allowInterop(wrapper);

    return _inner.onWrite(jsWrapper);
  }
}

class Event<T> {
  final T data;
  final String eventId;
  final String eventType;
  final Map<String, String> params;
  final String resource;
  final DateTime timestamp;

  Event({
    this.data,
    this.eventId,
    this.eventType,
    this.params,
    this.resource,
    this.timestamp,
  });
}

class DatabaseEvent extends Event<DeltaSnapshot> {
  DatabaseEvent({
    DeltaSnapshot data,
    String eventId,
    String eventType,
    Map<String, String> params,
    String resource,
    DateTime timestamp,
  })
      : super(
          data: data,
          eventId: eventId,
          eventType: eventType,
          params: params,
          resource: resource,
          timestamp: timestamp,
        );
}

class DeltaSnapshot {
  final js.DeltaSnapshot _inner;

  DeltaSnapshot._(this._inner);
  Reference get adminRef => new Reference._(_inner.adminRef);

  bool changed() => _inner.changed();

  DeltaSnapshot child(String path) => new DeltaSnapshot._(_inner.child(path));

  DeltaSnapshot get current => new DeltaSnapshot._(_inner.current);

  bool exists() => _inner.exists();

  bool hasChild(String path) => _inner.hasChild(path);

  bool hasChildren() => _inner.hasChildren();

  String get key => _inner.key;

  int numChildren() => _inner.numChildren();

  DeltaSnapshot get previous => new DeltaSnapshot._(_inner.previous);

  Reference get ref => new Reference._(_inner.ref);

  /// Returns current value which can be a `Map`, a `List` or any primitive type:
  /// `String`, `int`, `bool`, `null`.
  dynamic val() => dartify(_inner.val());

  // NOTE: intentionally not following JS library name – using Dart convention.
  /// Returns a JSON-serializable representation of this object.
  Object toJson() => dartify(_inner.toJSON());
}

class Reference {
  final js.Reference _inner;

  Reference._(this._inner);

  Reference child(String path) => new Reference._(_inner.child(path));

  Reference get parent => new Reference._(_inner.parent);

  Future<Null> set(dynamic value) {
    var jsValue = jsify(value);

    var promise = _inner.set(jsValue);
    return jsPromiseToFuture(promise);
  }
}
