// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Interop library for Firebase Functions Node.js SDK.
///
/// Use [functions] object as main entry point.
///
/// To create your cloud function see corresponding namespaces on
/// [FirebaseFunctions] class:
///
/// - [FirebaseFunctions.https] for creating HTTPS triggers
/// - [FirebaseFunctions.database] for creating Realtime Database triggers
/// - [FirebaseFunctions.firestore] for creating Firestore triggers
///
/// Here is an example of creating and exporting an HTTPS trigger:
///
///     import 'package:firebase_functions_interop/firebase_functions_interop.dart';
///
///     void main() {
///       // Registers helloWorld function under path prefix `/helloWorld`
///       functions['helloWorld'] = FirebaseFunctions.https
///         .onRequest(helloWorld);
///     }
///
///     // Simple function which returns a response with a body containing
///     // "Hello world".
///     void helloWorld(ExpressHttpRequest request) {
///       request.response.writeln("Hello world");
///       request.response.close();
///     }
library firebase_functions_interop;

import 'dart:async';
import 'dart:js';

import 'package:firebase_admin_interop/firebase_admin_interop.dart';
import 'package:meta/meta.dart';
import 'package:node_interop/http.dart';
import 'package:node_interop/node.dart';
import 'package:node_interop/util.dart';

import 'src/bindings.dart' as js;
import 'src/express.dart';

export 'package:firebase_admin_interop/firebase_admin_interop.dart';
export 'package:node_io/node_io.dart' show HttpRequest, HttpResponse;

export 'src/bindings.dart' show CloudFunction, HttpsFunction;
export 'src/express.dart';

/// Main library object which can be used to create and register Firebase
/// Cloud functions.
const FirebaseFunctions functions = const FirebaseFunctions._();

@Deprecated('Use "functions" instead.')
FirebaseFunctions get firebaseFunctions => functions;

final js.FirebaseFunctions _js = require('firebase-functions');

/// Global namespace for Firebase Cloud Functions functionality.
///
/// Use [functions] as a singleton instance of this class to export function
/// triggers.
class FirebaseFunctions {
  const FirebaseFunctions._();

  /// Configuration object for Firebase functions.
  static const Config config = const Config._();

  /// HTTPS functions.
  static const HttpsFunctions https = const HttpsFunctions._();

  /// Realtime Database functions.
  static const DatabaseFunctions database = const DatabaseFunctions._();

  /// Firestore functions
  static const FirestoreFunctions firestore = const FirestoreFunctions._();

  /// Pubsub functions
  static const PubsubFunctions pubsub = const PubsubFunctions._();

  // Storage functions
  static const StorageFunctions storage = const StorageFunctions._();

  /// Export [function] under specified [key].
  ///
  /// For HTTPS functions the [key] defines URL path prefix.
  operator []=(String key, dynamic function) {
    assert(function is js.HttpsFunction || function is js.CloudFunction);
    setExport(key, function);
  }
}

/// Provides access to environment configuration of Firebase Functions.
///
/// See also:
/// - [https://firebase.google.com/docs/functions/config-env](https://firebase.google.com/docs/functions/config-env)
class Config {
  const Config._();

  /// Returns configuration value specified by it's [key].
  ///
  /// This method expects keys to be fully qualified (namespaced), e.g.
  /// `some_service.client_secret` or `some_service.url`.
  /// This is different from native JS implementation where namespaced
  /// keys are broken into nested JS object structure, e.g.
  /// `functions.config().some_service.client_secret`.
  dynamic get(String key) {
    if (key == 'firebase') {
      return _js.config().firebase;
    }
    final List<String> parts = key.split('.');
    var data = dartify(_js.config());
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
  /// Firebase Admin SDK client.
  ///
  /// This is a shortcut for calling `get('firebase')`.
  AppOptions get firebase => get('firebase');
}

/// HTTPS functions namespace.
class HttpsFunctions {
  const HttpsFunctions._();

  /// Event [handler] which is run every time an HTTPS URL is hit.
  ///
  /// Returns a [js.HttpsFunction] which can be exported.
  ///
  /// The event handler is called with single [request] argument, instance
  /// of [ExpressHttpRequest]. This object acts as a
  /// proxy to JavaScript request and response objects.
  js.HttpsFunction onRequest(void handler(ExpressHttpRequest request)) {
    void jsHandler(IncomingMessage request, ServerResponse response) {
      var requestProxy = new ExpressHttpRequest(request, response);
      handler(requestProxy);
    }

    return _js.https.onRequest(allowInterop(jsHandler));
  }
}

/// Realtime Database functions namespace.
class DatabaseFunctions {
  const DatabaseFunctions._();

  /// Returns reference builder for specified [path] in Realtime Database.
  RefBuilder ref(String path) => new RefBuilder._(_js.database.ref(path));
}

/// The Firebase Realtime Database reference builder.
class RefBuilder {
  final js.RefBuilder nativeInstance;

  RefBuilder._(this.nativeInstance);

  /// Event handler that fires every time new data is created in Firebase
  /// Realtime Database.
  js.CloudFunction onCreate<T>(FutureOr<void> handler(DatabaseEvent<T> event)) {
    dynamic wrapper(js.Event event) => _handleEvent<T>(event, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is deleted from Firebase
  /// Realtime Database.
  js.CloudFunction onDelete<T>(FutureOr<void> handler(DatabaseEvent<T> event)) {
    dynamic wrapper(js.Event event) => _handleEvent<T>(event, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is updated in Firebase Realtime
  /// Database.
  js.CloudFunction onUpdate<T>(FutureOr<void> handler(DatabaseEvent<T> event)) {
    dynamic wrapper(js.Event event) => _handleEvent<T>(event, handler);
    return nativeInstance.onUpdate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Firebase Realtime Database write of
  /// any kind (creation, update, or delete) occurs.
  js.CloudFunction onWrite<T>(FutureOr<void> handler(DatabaseEvent<T> event)) {
    dynamic wrapper(js.Event event) => _handleEvent<T>(event, handler);
    return nativeInstance.onWrite(allowInterop(wrapper));
  }

  dynamic _handleEvent<T>(
      js.Event event, FutureOr<void> handler(DatabaseEvent<T> event)) {
    var dartEvent = new DatabaseEvent<T>(
      data: new DeltaSnapshot<T>(event.data),
      eventId: event.eventId,
      eventType: event.eventType,
      params: dartify(event.params),
      resource: event.resource,
      timestamp: DateTime.parse(event.timestamp),
    );
    var result = handler(dartEvent);
    if (result is Future) {
      return futureToPromise(result);
    }
    return null;
  }
}

/// Represents generic [Event] triggered by a Firebase service.
class Event<T> {
  /// Data returned for the event.
  ///
  /// The nature of the data depends on the [eventType].
  final T data;

  /// Unique identifier of this event.
  final String eventId;

  /// Type of this event.
  final String eventType;

  /// Values of the wildcards in the path parameter provided to the
  /// [DatabaseFunctions.ref] method for a Realtime Database trigger.
  final Map<String, String> params;

  /// The resource that emitted the event.
  final String resource;

  /// Timestamp for this event.
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

/// An [Event] triggered by Firebase Realtime Database.
class DatabaseEvent<T> extends Event<DeltaSnapshot<T>> {
  DatabaseEvent({
    DeltaSnapshot<T> data,
    String eventId,
    String eventType,
    Map<String, String> params,
    String resource,
    DateTime timestamp,
  }) : super(
          data: data,
          eventId: eventId,
          eventType: eventType,
          params: params,
          resource: resource,
          timestamp: timestamp,
        );
}

/// Represents a Firebase Realtime Database delta snapshot.
class DeltaSnapshot<T> extends DataSnapshot<T> {
  DeltaSnapshot(js.DeltaSnapshot nativeInstance) : super(nativeInstance);

  @override
  @protected
  js.DeltaSnapshot get nativeInstance => super.nativeInstance;

  /// Returns a [Reference] to the Database location where the triggering write
  /// occurred. Similar to [ref], but with full read and write access instead of
  /// end-user access.
  Reference get adminRef =>
      _adminRef ??= new Reference(nativeInstance.adminRef);
  Reference _adminRef;

  /// Tests whether data in the path has changed as a result of the triggered
  /// write.
  bool changed() => nativeInstance.changed();

  @override
  DeltaSnapshot<S> child<S>(String path) => super.child(path);

  /// Gets the current [DeltaSnapshot] after the triggering write event has
  /// occurred.
  DeltaSnapshot<T> get current => new DeltaSnapshot<T>(nativeInstance.current);

  /// Gets the previous state of the [DeltaSnapshot], from before the
  /// triggering write event.
  DeltaSnapshot<T> get previous =>
      new DeltaSnapshot<T>(nativeInstance.previous);
}

class FirestoreFunctions {
  const FirestoreFunctions._();

  DocumentBuilder document(String path) =>
      new DocumentBuilder._(_js.firestore.document(path));
}

class DocumentBuilder {
  @protected
  final js.DocumentBuilder nativeInstance;

  DocumentBuilder._(this.nativeInstance);

  /// Event handler that fires every time new data is created in Cloud Firestore.
  js.CloudFunction onCreate(FutureOr<void> handler(FirestoreEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is deleted from Cloud Firestore.
  js.CloudFunction onDelete(FutureOr<void> handler(FirestoreEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is updated in Cloud Firestore.
  js.CloudFunction onUpdate(FutureOr<void> handler(FirestoreEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onUpdate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Cloud Firestore write of any
  /// kind (creation, update, or delete) occurs.
  js.CloudFunction onWrite(FutureOr<void> handler(FirestoreEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onWrite(allowInterop(wrapper));
  }

  dynamic _handleEvent(
      js.Event jsEvent, FutureOr<void> handler(FirestoreEvent event)) {
    final FirestoreEvent event = new FirestoreEvent(
      data: new DeltaDocumentSnapshot(jsEvent.data),
      eventId: jsEvent.eventId,
      eventType: jsEvent.eventType,
      params: dartify(jsEvent.params),
      resource: jsEvent.resource,
      timestamp: DateTime.parse(jsEvent.timestamp),
    );
    var result = handler(event);
    if (result is Future) {
      return futureToPromise(result);
    }
    return null;
  }
}

class DeltaDocumentSnapshot extends DocumentSnapshot {
  DeltaDocumentSnapshot(js.DeltaDocumentSnapshot nativeInstance)
      : super(nativeInstance, new Firestore(nativeInstance.ref.firestore));

  @override
  @protected
  js.DeltaDocumentSnapshot get nativeInstance => super.nativeInstance;

  /// Previous state of the document before the triggering write event.
  DeltaDocumentSnapshot get previous =>
      new DeltaDocumentSnapshot(nativeInstance.previous);

  /// The last time the document was read, can be `null`.
  DateTime get readTime => (nativeInstance.readTime != null)
      ? DateTime.parse(nativeInstance.readTime)
      : null;
}

/// An [Event] triggered by Firestore Database.
class FirestoreEvent extends Event<DeltaDocumentSnapshot> {
  FirestoreEvent({
    DeltaDocumentSnapshot data,
    String eventId,
    String eventType,
    Map<String, String> params,
    String resource,
    DateTime timestamp,
  }) : super(
          data: data,
          eventId: eventId,
          eventType: eventType,
          params: params,
          resource: resource,
          timestamp: timestamp,
        );
}

class PubsubFunctions {
  const PubsubFunctions._();

  TopicBuilder topic(String path) => new TopicBuilder._(_js.pubsub.topic(path));
}

class TopicBuilder {
  @protected
  final js.TopicBuilder nativeInstance;

  TopicBuilder._(this.nativeInstance);

  /// Event handler that fires every time an event is published in Pubsub.
  js.CloudFunction onPublish(FutureOr<void> handler(PubsubEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onPublish(allowInterop(wrapper));
  }

  dynamic _handleEvent(
      js.Event jsEvent, FutureOr<void> handler(PubsubEvent event)) {
    final PubsubEvent event = new PubsubEvent(
      data: new Message(jsEvent.data),
      eventId: jsEvent.eventId,
      eventType: jsEvent.eventType,
      params: dartify(jsEvent.params),
      resource: jsEvent.resource,
      timestamp: DateTime.parse(jsEvent.timestamp),
    );
    var result = handler(event);
    if (result is Future) {
      return futureToPromise(result);
    }
    return null;
  }
}

class Message {
  Message(js.Message this.nativeInstance);

  @protected
  final js.Message nativeInstance;

  /// User-defined attributes published with the message, if any.
  Map<String, String> get attributes =>
      new Map<String, String>.from(dartify(nativeInstance.attributes));

  /// The data payload of this message object as a base64-encoded string.
  String get data => nativeInstance.data;

  /// The JSON data payload of this message object, if any.
  dynamic get json => dartify(nativeInstance.json);

  /// Returns a JSON-serializable representation of this object.
  dynamic toJson() => dartify(nativeInstance.toJSON());
}

class PubsubEvent extends Event<Message> {
  PubsubEvent({
    Message data,
    String eventId,
    String eventType,
    Map<String, String> params,
    String resource,
    DateTime timestamp,
  }) : super(
          data: data,
          eventId: eventId,
          eventType: eventType,
          params: params,
          resource: resource,
          timestamp: timestamp,
        );
}

class StorageFunctions {
  const StorageFunctions._();

  /// Registers a Cloud Function scoped to a specific storage [bucket].
  BucketBuilder bucket(String path) =>
      new BucketBuilder._(_js.storage.bucket(path));

  /// Registers a Cloud Function scoped to the default storage bucket for the project.
  ObjectBuilder object() => new ObjectBuilder._(_js.storage.object());
}

class BucketBuilder {
  @protected
  final js.BucketBuilder nativeInstance;

  BucketBuilder._(this.nativeInstance);

  /// Storage object builder interface scoped to the specified storage bucket.
  ObjectBuilder object() {
    return new ObjectBuilder._(nativeInstance.object());
  }
}

class ObjectBuilder {
  @protected
  final js.ObjectBuilder nativeInstance;

  ObjectBuilder._(this.nativeInstance);

  /// Event handler which fires every time a Google Cloud Storage change occurs.
  js.CloudFunction onChange(FutureOr<void> handler(StorageEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onChange(allowInterop(wrapper));
  }

  dynamic _handleEvent(
      js.Event jsEvent, FutureOr<void> handler(StorageEvent event)) {
    final StorageEvent event = new StorageEvent(
      data: new ObjectMetadata(jsEvent.data),
      eventId: jsEvent.eventId,
      eventType: jsEvent.eventType,
      params: dartify(jsEvent.params),
      resource: jsEvent.resource,
      timestamp: DateTime.parse(jsEvent.timestamp),
    );
    var result = handler(event);
    if (result is Future) {
      return futureToPromise(result);
    }
    return null;
  }
}

class ObjectMetadata {
  ObjectMetadata(js.ObjectMetadata this.nativeInstance);

  @protected
  final js.ObjectMetadata nativeInstance;

  String get bucket => nativeInstance.bucket;

  String get cacheControl => nativeInstance.cacheControl;

  int get componentCount => nativeInstance.componentCount;

  String get contentDisposition => nativeInstance.contentDisposition;

  String get contentEncoding => nativeInstance.contentEncoding;

  String get contentLanguage => nativeInstance.contentLanguage;

  String get contentType => nativeInstance.contentType;

  dynamic get customerEncryption => dartify(nativeInstance.customerEncryption);

  String get generation => nativeInstance.generation;

  String get id => nativeInstance.id;

  String get kind => nativeInstance.kind;

  String get md5Hash => nativeInstance.md5Hash;

  String get mediaLink => nativeInstance.mediaLink;

  dynamic get metadata => dartify(nativeInstance.mediaLink);

  String get metageneration => nativeInstance.metageneration;

  String get name => nativeInstance.name;

  String get resourceState => nativeInstance.resourceState;

  String get selfLink => nativeInstance.selfLink;

  String get size => nativeInstance.size;

  String get storageClass => nativeInstance.storageClass;

  String get timeCreated => nativeInstance.timeCreated;

  String get timeDeleted => nativeInstance.timeDeleted;

  String get updated => nativeInstance.updated;
}

class StorageEvent extends Event<ObjectMetadata> {
  StorageEvent({
    ObjectMetadata data,
    String eventId,
    String eventType,
    Map<String, String> params,
    String resource,
    DateTime timestamp,
  }) : super(
          data: data,
          eventId: eventId,
          eventType: eventType,
          params: params,
          resource: resource,
          timestamp: timestamp,
        );
}
