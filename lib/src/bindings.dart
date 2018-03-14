// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@JS()
library firebase_functions_interop.bindings;

import 'package:js/js.dart';
import 'package:node_interop/http.dart';
import 'package:firebase_admin_interop/js.dart' as admin;

@JS()
@anonymous
abstract class FirebaseFunctions {
  /// Store and retrieve project configuration data such as third-party API keys
  /// or other settings.
  ///
  /// You can set configuration values using the Firebase CLI as described in
  /// [Environment Configuration](https://firebase.google.com/docs/functions/config-env).
  external Config config();

  external HttpsFunctions get https;

  external DatabaseFunctions get database;

  external FirestoreFunctions get firestore;

  external PubsubFunctions get pubsub;

  external StorageFunctions get storage;

  external AuthFunctions get auth;

  /// Constructor for Firebase [Event] objects.
  external dynamic get Event;
}

/// The Cloud Function type for all non-HTTPS triggers.
///
/// This should be exported from your JavaScript file to define a Cloud Function.
/// This type is a special JavaScript function which takes a generic [Event]
/// object as its only argument.
typedef void CloudFunction<T>(Event<T> event);

/// The Cloud Function type for HTTPS triggers.
///
/// This should be exported from your JavaScript file to define a Cloud
/// Function. This type is a special JavaScript function which takes Express
/// Request and Response objects as its only arguments.
typedef void HttpsFunction(IncomingMessage request, ServerResponse response);

@JS()
@anonymous
abstract class Event<T> {
  /// Data returned for the event. The nature of the data depends on the event
  /// type.
  external T get data;

  /// The event’s unique identifier.
  external String get eventId;

  /// Type of event.
  ///
  /// Valid values are:
  /// - `providers/google.firebase.analytics/eventTypes/event.log`
  /// - `providers/google.firebase.database/eventTypes/ref.write`
  /// - `providers/google.firebase.database/eventTypes/ref.create`
  /// - `providers/google.firebase.database/eventTypes/ref.update`
  /// - `providers/google.firebase.database/eventTypes/ref.delete`
  /// - `providers/firebase.auth/eventTypes/user.create`
  /// - `providers/firebase.auth/eventTypes/user.delete`
  /// - `providers/cloud.pubsub/eventTypes/topic.publish`
  /// - `providers/cloud.storage/eventTypes/object.change`
  external String get eventType;

  /// An object containing the values of the wildcards in the path parameter
  /// provided to the [Database.ref] method for a Realtime Database trigger.
  external dynamic get params;

  /// The resource that emitted the event.
  ///
  /// Valid values are:
  ///
  /// - Analytics — projects/<projectId>/events/<analyticsEventType>
  /// - Realtime Database — projects/_/instances/<databaseInstance>/refs/<databasePath>
  /// - Storage — projects/_/buckets/<bucketName>/objects/<fileName>#<generation>
  /// - Authentication — projects/<projectId>
  /// - Pub/Sub — projects/<projectId>/topics/<topicName>
  ///
  /// Because Realtime Database instances and Cloud Storage buckets are globally
  /// unique and not tied to the project, their resources start with projects/_.
  /// Underscore is not a valid project name.
  external String get resource;

  /// Timestamp for the event.
  ///
  /// Formatted as an [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) string.
  external String get timestamp;
}

@JS()
@anonymous
abstract class Config {
  /// The Firebase configuration object which can be used to initialize the
  /// Firebase Admin Node.js SDK.
  external admin.AppOptions get firebase;
}

@JS()
@anonymous
abstract class HttpsFunctions {
  /// Event handler which is run every time an HTTPS URL is hit.
  ///
  /// The event handler is called with Express Request and Response objects as its
  /// only arguments.
  external HttpsFunction onRequest(HttpRequestListener handler);
}

@JS()
@anonymous
abstract class DatabaseFunctions {
  /// Registers a function that triggers on Firebase Realtime Database write
  /// events.
  ///
  /// This method behaves very similarly to the method of the same name in the
  /// client and Admin Firebase SDKs. Any change to the Database that affects the
  /// data at or below the provided path will fire an event in Cloud Functions.
  external RefBuilder ref(String path);
}

/// The Firebase Realtime Database reference builder interface.
@JS()
@anonymous
abstract class RefBuilder {
  /// Event handler that fires every time new data is created in Firebase
  /// Realtime Database.
  external CloudFunction onCreate(dynamic handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time data is deleted from Firebase Realtime
  /// Database.
  external CloudFunction onDelete(dynamic handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time data is updated in Firebase Realtime
  /// Database.
  external CloudFunction onUpdate(dynamic handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time a Firebase Realtime Database write of
  /// any kind (creation, update, or delete) occurs.
  external CloudFunction onWrite(dynamic handler(Event<DeltaSnapshot> event));
}

/// Interface representing a Firebase Realtime Database delta snapshot.
@JS()
@anonymous
abstract class DeltaSnapshot extends admin.DataSnapshot {
  external admin.Reference get adminRef;

  external DeltaSnapshot get current;

  external DeltaSnapshot get previous;

  external bool changed();

  @override
  external DeltaSnapshot child(String path);
}

@JS()
@anonymous
abstract class FirestoreFunctions {
  /// Registers a function that triggers on Cloud Firestore write events to
  /// the [document].
  external DocumentBuilder document(String document);
}

/// The Cloud Firestore document builder interface.
@JS()
@anonymous
abstract class DocumentBuilder {
  /// Event handler that fires every time new data is created in Cloud
  /// Firestore.
  external CloudFunction onCreate(
      void handler(Event<DeltaDocumentSnapshot> event));

  /// Event handler that fires every time data is deleted from Cloud Firestore.
  external CloudFunction onDelete(
      void handler(Event<DeltaDocumentSnapshot> event));

  /// Event handler that fires every time data is updated in Cloud Firestore.
  external CloudFunction onUpdate(
      void handler(Event<DeltaDocumentSnapshot> event));

  /// Event handler that fires every time a Cloud Firestore write of any kind
  /// (creation, update, or delete) occurs.
  external CloudFunction onWrite(
      void handler(Event<DeltaDocumentSnapshot> event));
}

/// Interface representing a Cloud Firestore delta document snapshot.
@JS()
@anonymous
abstract class DeltaDocumentSnapshot implements admin.DocumentSnapshot {
  /// The date the document was created, formatted as a UTC string.
  external String get createTime;

  /// Returns `true` if this DocumentDeltaSnapshot contains any data.
  external bool get exists;

  /// Extracts a document ID from a DocumentDeltaSnapshot.
  external String get id;

  /// Gets the previous state of this document, from before the triggering write
  /// event.
  external DeltaDocumentSnapshot get previous;

  /// The last time the document was read, formatted as a UTC string.
  external String get readTime;

  /// Returns a DocumentReference to the database location where the triggering
  /// write occurred. This DocumentReference has admin privileges.
  external admin.DocumentReference get ref;

  /// The last update time for the document, formatted as a UTC string.
  external String get updateTime;

  /// Returns the data fields in their state after the triggering write event
  /// has occurred.
  external dynamic data();

  /// Gets the value for a given key.
  external dynamic get(key);
}

@JS()
@anonymous
abstract class PubsubFunctions {
  /// Registers a function that triggers on Pubsub write events to
  /// the [topic].
  external TopicBuilder topic(String topic);
}

/// The Pubsub topic builder interface.
@JS()
@anonymous
abstract class TopicBuilder {
  /// Event handler that fires every time an event is publish in Pubsub.
  external CloudFunction onPublish(void handler(Event<Message> event));
}

/// Interface representing a Google Cloud Pub/Sub message.
@JS()
@anonymous
abstract class Message {
  /// User-defined attributes published with the message, if any.
  external dynamic get attributes;

  /// The data payload of this message object as a base64-encoded string.
  external String get data;

  /// The JSON data payload of this message object, if any.
  external dynamic get json;

  /// Returns a JSON-serializable representation of this object.
  external dynamic toJSON();
}

@JS()
@anonymous
abstract class StorageFunctions {
  /// Registers a Cloud Function scoped to a specific storage [bucket].
  external BucketBuilder bucket(String bucket);

  /// Registers a Cloud Function scoped to the default storage bucket for the project.
  external ObjectBuilder object();
}

/// The Storage bucket builder interface.
@JS()
@anonymous
abstract class BucketBuilder {
  /// Storage object builder interface scoped to the specified storage bucket.
  external ObjectBuilder object();
}

/// The Storage object builder interface.
@JS()
@anonymous
abstract class ObjectBuilder {
  /// Event handler which fires every time a Google Cloud Storage change occurs.
  external CloudFunction onChange(void handler(Event<ObjectMetadata> event));
}

/// Interface representing a Google Google Cloud Storage object metadata object.
@JS()
@anonymous
abstract class ObjectMetadata {
  /// Storage bucket that contains the object.
  external String get bucket;

  /// The value of the `Cache-Control` header, used to determine whether Internet
  /// caches are allowed to cache public data for an object.
  external String get cacheControl;

  /// Specifies the number of originally uploaded objects from which a composite
  /// object was created.
  external int get componentCount;

  /// The value of the `Content-Disposition` header, used to specify presentation
  /// information about the data being transmitted.
  external String get contentDisposition;

  /// Content encoding to indicate that an object is compressed (for example,
  /// with gzip compression) while maintaining its Content-Type.
  external String get contentEncoding;

  /// ISO 639-1 language code of the content.
  external String get contentLanguage;

  /// The object's content type, also known as the MIME type.
  external String get contentType;

  /// The object's CRC32C hash. All Google Cloud Storage objects have a CRC32C
  /// hash or MD5 hash.
  external String get crc32c;

  /// Customer-supplied encryption key.
  external dynamic get customerEncryption;

  /// Generation version number that changes each time the object is overwritten.
  external String get generation;

  /// The ID of the object, including the bucket name, object name, and generation
  /// number.
  external String get id;

  /// The kind of the object, which is always `storage#object`.
  external String get kind;

  /// MD5 hash for the object. All Google Cloud Storage objects have a CRC32C hash
  /// or MD5 hash.
  external String get md5Hash;

  /// Media download link.
  external String get mediaLink;

  /// User-provided metadata.
  external Map<String, dynamic> get metadata;

  /// Meta-generation version number that changes each time the object's metadata
  /// is updated.
  external String get metageneration;

  /// The object's name.
  external String get name;

  /// The current state of this object resource.
  ///
  /// The value can be either "exists" (for object creation and updates) or
  /// "not_exists" (for object deletion and moves).
  external String get resourceState;

  /// Link to access the object, assuming you have sufficient permissions.
  external String get selfLink;

  /// The value of the `Content-Length` header, used to determine the length of
  /// this object data in bytes.
  external String get size;

  /// Storage class of this object.
  external String get storageClass;

  /// The creation time of this object in RFC 3339 format.
  external String get timeCreated;

  /// The deletion time of the object in RFC 3339 format. Returned only if this
  /// version of the object has been deleted.
  external String get timeDeleted;

  /// The modification time of this object.
  external String get updated;
}

/// Namespace for Firebase Authentication functions.
@JS()
@anonymous
abstract class AuthFunctions {
  /// Registers a Cloud Function to handle user authentication events.
  external UserBuilder user();
}

/// The Firebase Authentication user builder interface.
@JS()
@anonymous
abstract class UserBuilder {
  /// Event handler that fires every time a Firebase Authentication user is created.
  external CloudFunction onCreate(void handler(Event<UserRecord> event));

  /// Event handler that fires every time a Firebase Authentication user is deleted.
  external CloudFunction onDelete(void handler(Event<UserRecord> event));
}

/// Interface representing a user.
@JS()
@anonymous
abstract class UserRecord {
  /// Whether or not the user is disabled.
  external bool get disabled;

  /// The user's display name.
  external String get displayName;

  /// The user's primary email, if set.
  external String get email;

  /// Whether or not the user's primary email is verified.
  external bool get emailVerified;

  /// Additional metadata about the user.
  external admin.UserMetadata get metadata;

  /// The user's photo URL.
  external String get photoURL;

  /// An array of providers (for example, Google, Facebook) linked to the user.
  external List<admin.UserInfo> get providerData;

  /// The user's uid.
  external String get uid;

  /// Returns the serialized JSON representation of this object.
  external dynamic toJSON();
}
