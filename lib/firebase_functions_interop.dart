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

export 'src/bindings.dart' show CloudFunction, HttpsFunction, EventAuthInfo;
export 'src/express.dart';

part 'src/https.dart';

/// Main library object which can be used to create and register Firebase
/// Cloud functions.
const FirebaseFunctions functions = const FirebaseFunctions._();

@Deprecated('Use "functions" instead.')
FirebaseFunctions get firebaseFunctions => functions;

final js.FirebaseFunctions _js = require('firebase-functions');

typedef DataEventHandler<T> = FutureOr<void> Function(
    T data, EventContext context);
typedef ChangeEventHandler<T> = FutureOr<void> Function(
    Change<T> data, EventContext context);

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
}

/// Container for events that change state, such as Realtime Database or
/// Cloud Firestore `onWrite` and `onUpdate`.
class Change<T> {
  Change(this.after, this.before);

  /// The state after the event.
  final T after;

  /// The state prior to the event.
  final T before;
}

/// The context in which an event occurred.
///
/// An EventContext describes:
///
///   * The time an event occurred.
///   * A unique identifier of the event.
///   * The resource on which the event occurred, if applicable.
///   * Authorization of the request that triggered the event, if applicable
///     and available.
class EventContext {
  EventContext._(this.auth, this.authType, this.eventId, this.eventType,
      this.params, this.resource, this.timestamp);

  factory EventContext(js.EventContext data) {
    return new EventContext._(
      data.auth,
      data.authType,
      data.eventId,
      data.eventType,
      new Map<String, String>.from(dartify(data.params)),
      data.resource,
      DateTime.parse(data.timestamp),
    );
  }

  /// Authentication information for the user that triggered the function.
  ///
  /// For an unauthenticated user, this field is null. For event types that do
  /// not provide user information (all except Realtime Database) or for
  /// Firebase admin users, this field will not exist.
  final js.EventAuthInfo auth;

  /// The level of permissions for a user.
  ///
  /// Valid values are: `ADMIN`, `USER`, `UNAUTHENTICATED` and `null`.
  final String authType;

  /// The event’s unique identifier.
  final String eventId;

  /// Type of event.
  final String eventType;

  /// An object containing the values of the wildcards in the path parameter
  /// provided to the ref() method for a Realtime Database trigger.
  final Map<String, String> params;

  /// The resource that emitted the event.
  final String resource;

  /// Timestamp for the event.
  final DateTime timestamp;
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
  js.CloudFunction onCreate<T>(DataEventHandler<DataSnapshot<T>> handler) {
    dynamic wrapper(js.DataSnapshot data, js.EventContext context) =>
        _handleDataEvent<T>(data, context, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is deleted from Firebase
  /// Realtime Database.
  js.CloudFunction onDelete<T>(DataEventHandler<DataSnapshot<T>> handler) {
    dynamic wrapper(js.DataSnapshot data, js.EventContext context) =>
        _handleDataEvent<T>(data, context, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is updated in Firebase Realtime
  /// Database.
  js.CloudFunction onUpdate<T>(ChangeEventHandler<DataSnapshot<T>> handler) {
    dynamic wrapper(js.Change<js.DataSnapshot> data, js.EventContext context) =>
        _handleChangeEvent<T>(data, context, handler);
    return nativeInstance.onUpdate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Firebase Realtime Database write of
  /// any kind (creation, update, or delete) occurs.
  js.CloudFunction onWrite<T>(ChangeEventHandler<DataSnapshot<T>> handler) {
    dynamic wrapper(js.Change<js.DataSnapshot> data, js.EventContext context) =>
        _handleChangeEvent<T>(data, context, handler);
    return nativeInstance.onWrite(allowInterop(wrapper));
  }

  dynamic _handleDataEvent<T>(js.DataSnapshot data, js.EventContext jsContext,
      FutureOr<void> handler(DataSnapshot<T> data, EventContext context)) {
    var snapshot = new DataSnapshot<T>(data);
    var context = new EventContext(jsContext);
    var result = handler(snapshot, context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
  }

  dynamic _handleChangeEvent<T>(js.Change<js.DataSnapshot> data,
      js.EventContext jsContext, ChangeEventHandler<DataSnapshot<T>> handler) {
    var after = new DataSnapshot<T>(data.after);
    var before = new DataSnapshot<T>(data.before);
    var context = new EventContext(jsContext);
    var result = handler(new Change<DataSnapshot<T>>(after, before), context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
  }
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
  js.CloudFunction onCreate(DataEventHandler<DocumentSnapshot> handler) {
    dynamic wrapper(js.DocumentSnapshot data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is deleted from Cloud Firestore.
  js.CloudFunction onDelete(DataEventHandler<DocumentSnapshot> handler) {
    dynamic wrapper(js.DocumentSnapshot data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  /// Event handler that fires every time data is updated in Cloud Firestore.
  js.CloudFunction onUpdate(ChangeEventHandler<DocumentSnapshot> handler) {
    dynamic wrapper(
            js.Change<js.DocumentSnapshot> data, js.EventContext context) =>
        _handleChangeEvent(data, context, handler);
    return nativeInstance.onUpdate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Cloud Firestore write of any
  /// kind (creation, update, or delete) occurs.
  js.CloudFunction onWrite(ChangeEventHandler<DocumentSnapshot> handler) {
    dynamic wrapper(
            js.Change<js.DocumentSnapshot> data, js.EventContext context) =>
        _handleChangeEvent(data, context, handler);
    return nativeInstance.onWrite(allowInterop(wrapper));
  }

  dynamic _handleEvent(js.DocumentSnapshot data, js.EventContext jsContext,
      DataEventHandler<DocumentSnapshot> handler) {
    final firestore = new Firestore(data.ref.firestore);
    final snapshot = new DocumentSnapshot(data, firestore);
    final context = new EventContext(jsContext);
    var result = handler(snapshot, context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
  }

  dynamic _handleChangeEvent(js.Change<js.DocumentSnapshot> data,
      js.EventContext jsContext, ChangeEventHandler<DocumentSnapshot> handler) {
    final firestore = new Firestore(data.after.ref.firestore);
    var after = new DocumentSnapshot(data.after, firestore);
    var before = new DocumentSnapshot(data.before, firestore);
    var context = new EventContext(jsContext);
    var result = handler(new Change<DocumentSnapshot>(after, before), context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
  }
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
  js.CloudFunction onPublish(DataEventHandler<Message> handler) {
    dynamic wrapper(js.Message jsData, js.EventContext jsContext) =>
        _handleEvent(jsData, jsContext, handler);
    return nativeInstance.onPublish(allowInterop(wrapper));
  }

  dynamic _handleEvent(js.Message jsData, js.EventContext jsContext,
      DataEventHandler<Message> handler) {
    final message = new Message(jsData);
    final context = new EventContext(jsContext);
    var result = handler(message, context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
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

  /// Event handler sent only when a bucket has enabled object versioning.
  ///
  /// This event indicates that the live version of an object has become an
  /// archived version, either because it was archived or because it was
  /// overwritten by the upload of an object of the same name.
  js.CloudFunction onArchive(DataEventHandler<ObjectMetadata> handler) {
    dynamic wrapper(js.ObjectMetadata data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onArchive(allowInterop(wrapper));
  }

  /// Event handler which fires every time a Google Cloud Storage deletion
  /// occurs.
  ///
  /// Sent when an object has been permanently deleted. This includes objects
  /// that are overwritten or are deleted as part of the bucket's lifecycle
  /// configuration. For buckets with object versioning enabled, this is not
  /// sent when an object is archived, even if archival occurs via the
  /// storage.objects.delete method.
  js.CloudFunction onDelete(DataEventHandler<ObjectMetadata> handler) {
    dynamic wrapper(js.ObjectMetadata data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  /// Event handler which fires every time a Google Cloud Storage object
  /// creation occurs.
  ///
  /// Sent when a new object (or a new generation of an existing object) is
  /// successfully created in the bucket. This includes copying or rewriting an
  /// existing object. A failed upload does not trigger this event.
  js.CloudFunction onFinalize(DataEventHandler<ObjectMetadata> handler) {
    dynamic wrapper(js.ObjectMetadata data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onFinalize(allowInterop(wrapper));
  }

  /// Event handler which fires every time the metadata of an existing object
  /// changes.
  js.CloudFunction onMetadataUpdate(DataEventHandler<ObjectMetadata> handler) {
    dynamic wrapper(js.ObjectMetadata data, js.EventContext context) =>
        _handleEvent(data, context, handler);
    return nativeInstance.onMetadataUpdate(allowInterop(wrapper));
  }

  dynamic _handleEvent(js.ObjectMetadata jsData, js.EventContext jsContext,
      DataEventHandler<ObjectMetadata> handler) {
    final data = new ObjectMetadata(jsData);
    final context = new EventContext(jsContext);
    var result = handler(data, context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
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
  js.CloudFunction onCreate(DataEventHandler<UserRecord> handler) {
    dynamic wrapper(js.UserRecord jsData, js.EventContext jsContext) =>
        _handleEvent(jsData, jsContext, handler);
    return nativeInstance.onCreate(allowInterop(wrapper));
  }

  /// Event handler that fires every time a Firebase Authentication user is deleted.
  js.CloudFunction onDelete(DataEventHandler<UserRecord> handler) {
    dynamic wrapper(js.UserRecord jsData, js.EventContext jsContext) =>
        _handleEvent(jsData, jsContext, handler);
    return nativeInstance.onDelete(allowInterop(wrapper));
  }

  dynamic _handleEvent(js.UserRecord jsData, js.EventContext jsContext,
      DataEventHandler<UserRecord> handler) {
    final data = new UserRecord(jsData);
    final context = new EventContext(jsContext);
    var result = handler(data, context);
    if (result is Future) {
      return futureToPromise(result);
    }
    // See: https://stackoverflow.com/questions/47128440/google-firebase-errorfunction-returned-undefined-expected-promise-or-value
    return 0;
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
