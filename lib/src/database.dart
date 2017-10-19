// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:js' as js;
import 'package:node_interop/node_interop.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:built_value/serializer.dart';

import 'bindings.dart' as js;

Database createImpl() => new Database._();

class Database {
  Database._();

  RefBuilder ref(String path) => new RefBuilder._(js.ref(path));
}

class RefBuilder {
  final js.RefBuilder _inner;

  RefBuilder._(this._inner);

  js.CloudFunction onWrite<T>(FutureOr<Null> handler(DatabaseEvent event), [Serializer<T> serializer]) {
    dynamic wrapper(js.Event event) {
      var dartEvent = new DatabaseEvent(
        data: new DeltaSnapshot(event.data, serializer),
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

class DeltaSnapshot<T> extends DataSnapshot<T> {
  DeltaSnapshot(js.DeltaSnapshot nativeInstance, [Serializer<T> serializer])
      : super(nativeInstance, serializer);

  js.DeltaSnapshot get nativeInstance => super.nativeInstance;

  /// Returns a [Reference] to the Database location where the triggering write
  /// occurred. Similar to [ref], but with full read and write access instead of
  /// end-user access.
  Reference get adminRef => new Reference(nativeInstance.adminRef);

  /// Tests whether data in the path has changed as a result of the triggered
  /// write.
  bool changed() => nativeInstance.changed();

  @override
  DeltaSnapshot<S> child<S>(String path, [Serializer<S> serializer]) =>
      super.child(path, serializer);

  /// Gets the current [DeltaSnapshot] after the triggering write event has
  /// occurred.
  DeltaSnapshot get current => new DeltaSnapshot(nativeInstance.current);

  /// Gets the previous state of the [DeltaSnapshot], from before the
  /// triggering write event.
  DeltaSnapshot get previous => new DeltaSnapshot(nativeInstance.previous);
}
