import 'dart:async';
import 'dart:js' as js;
import 'package:js/js_util.dart' as util;
import 'package:node_interop/node_interop.dart';

import 'bindings.dart';

Database createImpl(JsDatabase source) => new Database._(source);

class Database {
  final JsDatabase _inner;

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
  final JsRefBuilder _inner;

  RefBuilder._(this._inner);

  JsCloudFunction onWrite(FutureOr<Null> handler(DatabaseEvent event)) {
    dynamic wrapper(JsEvent event) {
      var dartEvent = new DatabaseEvent(
        data: new DeltaSnapshot._(event.data),
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

    var jsWrapper = js.allowInterop(wrapper);

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
  dynamic val() {
    return dartify(_inner.val());
  }
}

class Reference {
  final JsReference _inner;

  Reference._(this._inner);

  Reference child(String path) => new Reference._(_inner.child(path));

  Reference get parent => new Reference._(_inner.parent);

  Future<Null> set(dynamic value) {
    var jsValue = jsify(value);

    // Firebase calls onComplete with two arguments even though it's documented
    // as only accepting one.
    void onComplete(error, undocumented) {
      print(
          'Completed with error "$error" and undocumented param "$undocumented"');
    }

    var promise = _inner.set(jsValue, js.allowInterop(onComplete));
    return jsPromiseToFuture(promise);
  }
}

/// Returns Dart representation from JS Object.
dynamic dartify(Object jsObject) {
  if (_isBasicType(jsObject)) {
    return jsObject;
  }

  if (jsObject is List) {
    return jsObject.map(dartify).toList();
  }

  // TODO: this helper doesn't "fix" nested objects, like other lists or maps...
  return jsObjectToMap(jsObject);
}

/// Returns the JS implementation from Dart Object.
dynamic jsify(Object dartObject) {
  if (_isBasicType(dartObject)) {
    return dartObject;
  }

  return util.jsify(dartObject);
}

/// Returns [:true:] if the [value] is a very basic built-in type - e.g.
/// [null], [num], [bool] or [String]. It returns [:false:] in the other case.
bool _isBasicType(value) {
  if (value == null || value is num || value is bool || value is String) {
    return true;
  }
  return false;
}
