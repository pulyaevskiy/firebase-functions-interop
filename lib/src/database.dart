import 'dart:async';
import 'dart:js';

import 'package:node_interop/node_interop.dart';

import 'bindings.dart';

Database createImpl(JsDatabase source) => new Database._(source);

class Database {
  final JsDatabase _inner;

  Database._(this._inner);

  RefBuilder ref(String path) => new RefBuilder._(_inner.ref(path));
}

class RefBuilder {
  final JsRefBuilder _inner;

  RefBuilder._(this._inner);

  JsCloudFunction onWrite(FutureOr<Null> handler(DatabaseEvent event)) {
    dynamic wrapper(JsEvent event) {
      var dartEvent = new DatabaseEvent(
        data: new DeltaSnapshot(event.data),
        eventId: event.eventId,
        eventType: event.eventType,
        params: jsObjectToMap(event.params),
        resource: event.resource,
        timestamp: DateTime.parse(event.timestamp),
      );
      var result = handler(dartEvent);
      if (result is Future) {
        return futureToJsPromise(result);
      }
      return null;
    }

    var jsWrapper = allowInterop(wrapper);

    return _inner.onWrite(jsWrapper);
  }
}

class Event<T> implements JsEvent {
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
  final JsDeltaSnapshot _inner;

  DeltaSnapshot(this._inner);

  Reference get adminRef => new Reference._(_inner.adminRef);

  bool changed() => _inner.changed();

  DeltaSnapshot child(String path) => new DeltaSnapshot(_inner.child(path));

  DeltaSnapshot get current => new DeltaSnapshot(_inner.current);

  bool exists() => _inner.exists();

  bool hasChild(String path) => _inner.hasChild(path);

  bool hasChildren() => _inner.hasChildren();

  String get key => _inner.key;

  int numChildren() => _inner.numChildren();

  DeltaSnapshot get previous => new DeltaSnapshot(_inner.previous);

  Reference get ref => new Reference._(_inner.ref);

  /// Returns current value which can be a `Map`, a `List` or any primitive type:
  /// `String`, `int`, `bool`, `null`.
  dynamic val() {
    var value = _inner.val();
    if (value is String ||
        value is double ||
        value is int ||
        value is bool ||
        value == null) {
      return value;
    } else if (value is JsObject) {
      return jsObjectToMap(_inner.val());
    } else {
      throw new UnimplementedError(
          'Unsupported value type: ${value.runtimeType}');
    }
  }
}

class Reference {
  final JsReference _inner;

  Reference._(this._inner);

  Reference child(String path) => new Reference._(_inner.child(path));

  Reference get parent => new Reference._(_inner.parent);

  Future<Null> set(dynamic value) {
    var jsValue;
    if (value is String ||
        value is double ||
        value is int ||
        value is bool ||
        value == null) {
      jsValue = value;
    } else if (value is JsObject) {
      jsValue = new JsObject.jsify(value);
    } else {
      throw new UnsupportedError(
          'Unsupported value type: ${value.runtimeType}');
    }

    // Firebase calls onComplete with two arguments even though it's documented
    // as only accepting one.
    void onComplete(error, undocumented) {
      print(
          'Completed with error "$error" and undocumented param "$undocumented"');
    }

    var promise = _inner.set(jsValue, allowInterop(onComplete));
    return jsPromiseToFuture(promise);
  }
}
