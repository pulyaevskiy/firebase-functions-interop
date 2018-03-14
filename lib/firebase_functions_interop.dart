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

  /// Storage functions
  static const StorageFunctions storage = const StorageFunctions._();

  /// Namespace for Firebase Authentication functions.
  static const AuthFunctions auth = const AuthFunctions._();

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
  ObjectBuilder object() => new ObjectBuilder._(nativeInstance.object());
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

/// Interface representing a Google Google Cloud Storage object metadata object.
class ObjectMetadata {
  ObjectMetadata(js.ObjectMetadata this.nativeInstance);

  @protected
  final js.ObjectMetadata nativeInstance;

  /// Storage bucket that contains the object.
  String get bucket => nativeInstance.bucket;

  /// The value of the `Cache-Control` header, used to determine whether Internet
  /// caches are allowed to cache public data for an object.
  String get cacheControl => nativeInstance.cacheControl;

  /// Specifies the number of originally uploaded objects from which a composite
  /// object was created.
  int get componentCount => nativeInstance.componentCount;

  /// The value of the `Content-Disposition` header, used to specify presentation
  /// information about the data being transmitted.
  String get contentDisposition => nativeInstance.contentDisposition;

  /// Content encoding to indicate that an object is compressed (for example,
  /// with gzip compression) while maintaining its Content-Type.
  String get contentEncoding => nativeInstance.contentEncoding;

  /// ISO 639-1 language code of the content.
  String get contentLanguage => nativeInstance.contentLanguage;

  /// The object's content type, also known as the MIME type.
  String get contentType => nativeInstance.contentType;

  /// The object's CRC32C hash. All Google Cloud Storage objects have a CRC32C
  /// hash or MD5 hash.
  String get crc32c => nativeInstance.crc32c;

  /// Customer-supplied encryption key.
  CustomerEncryption get customerEncryption {
    final dartified = dartify(nativeInstance.customerEncryption);
    if (dartified == null) return null;
    return new CustomerEncryption(
      encryptionAlgorithm: dartified['encryptionAlgorithm'],
      keySha256: dartified['keySha256'],
    );
  }

  /// Generation version number that changes each time the object is overwritten.
  String get generation => nativeInstance.generation;

  /// The ID of the object, including the bucket name, object name, and generation
  /// number.
  String get id => nativeInstance.id;

  /// The kind of the object, which is always `storage#object`.
  String get kind => nativeInstance.kind;

  /// MD5 hash for the object. All Google Cloud Storage objects have a CRC32C hash
  /// or MD5 hash.
  String get md5Hash => nativeInstance.md5Hash;

  /// Media download link.
  String get mediaLink => nativeInstance.mediaLink;

  /// User-provided metadata.
  Map<String, dynamic> get metadata => dartify(nativeInstance.metadata);

  /// Meta-generation version number that changes each time the object's metadata
  /// is updated.
  String get metageneration => nativeInstance.metageneration;

  /// The object's name.
  String get name => nativeInstance.name;

  /// The current state of this object resource.
  ///
  /// The value can be either "exists" (for object creation and updates) or
  /// "not_exists" (for object deletion and moves).
  String get resourceState => nativeInstance.resourceState;

  /// Link to access the object, assuming you have sufficient permissions.
  String get selfLink => nativeInstance.selfLink;

  /// The value of the `Content-Length` header, used to determine the length of
  /// this object data in bytes.
  String get size => nativeInstance.size;

  /// Storage class of this object.
  String get storageClass => nativeInstance.storageClass;

  /// The creation time of this object.
  DateTime get timeCreated => nativeInstance.timeCreated == null
      ? null
      : DateTime.parse(nativeInstance.timeCreated);

  /// The deletion time of this object.
  ///
  /// Returned only if this version of the object has been deleted.
  DateTime get timeDeleted => nativeInstance.timeDeleted == null
      ? null
      : DateTime.parse(nativeInstance.timeDeleted);

  /// The modification time of this object.
  DateTime get updated => nativeInstance.updated == null
      ? null
      : DateTime.parse(nativeInstance.updated);
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

class CustomerEncryption {
  final String encryptionAlgorithm;
  final String keySha256;

  CustomerEncryption({this.encryptionAlgorithm, this.keySha256});
}

/// Namespace for Firebase Authentication functions.
class AuthFunctions {
  const AuthFunctions._();

  /// Registers a Cloud Function to handle user authentication events.
  UserBuilder user() => new UserBuilder._(_js.auth.user());
}

/// The Firebase Authentication user builder interface.
class UserBuilder {
  @protected
  final js.UserBuilder nativeInstance;

  UserBuilder._(this.nativeInstance);

  /// Event handler that fires every time a Firebase Authentication user is created.
  js.CloudFunction onCreate(FutureOr<void> handler(AuthEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Firebase Authentication user is deleted.
  js.CloudFunction onDelete(FutureOr<void> handler(AuthEvent event)) {
    dynamic wrapper(js.Event jsEvent) => _handleEvent(jsEvent, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  dynamic _handleEvent(
      js.Event jsEvent, FutureOr<void> handler(AuthEvent event)) {
    final AuthEvent event = new AuthEvent(
      data: new UserRecord(jsEvent.data),
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

/// Interface representing a user.
class UserRecord {
  UserRecord(js.UserRecord this.nativeInstance);

  @protected
  final js.UserRecord nativeInstance;

  /// Whether or not the user is disabled.
  bool get disabled => nativeInstance.disabled;

  /// The user's display name.
  String get displayName => nativeInstance.displayName;

  /// The user's primary email, if set.
  String get email => nativeInstance.email;

  /// Whether or not the user's primary email is verified.
  bool get emailVerified => nativeInstance.emailVerified;

  /// Additional metadata about the user.
  UserMetadata get metadata => nativeInstance.metadata;

  /// The user's photo URL.
  String get photoURL => nativeInstance.photoURL;

  /// An array of providers (for example, Google, Facebook) linked to the user.
  List<UserInfo> get providerData => nativeInstance.providerData;

  /// The user's uid.
  String get uid => nativeInstance.uid;

  /// Returns a JSON-serializable representation of this object.
  dynamic toJson() => dartify(nativeInstance.toJSON());
}

class AuthEvent extends Event<UserRecord> {
  AuthEvent({
    UserRecord data,
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
