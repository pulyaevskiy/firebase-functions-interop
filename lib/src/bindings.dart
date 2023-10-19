// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@JS()
library firebase_functions_interop.bindings;

import 'package:firebase_admin_interop/js.dart' as admin;
import 'package:js/js.dart';
import 'package:node_interop/http.dart';

export 'package:firebase_admin_interop/js.dart';

@JS()
@anonymous
abstract class RuntimeOptions {
  /// Timeout for the function in seconds.
  external int get timeoutSeconds;

  /// Amount of memory to allocate to the function.
  ///
  /// Valid values are: '128MB', '256MB', '512MB', '1GB', and '2GB'.
  external String get memory;

  external factory RuntimeOptions({int? timeoutSeconds, String? memory});
}

@JS()
@anonymous
@staticInterop
abstract class FirebaseFunctions {}

extension FirebaseFunctionsExt on FirebaseFunctions {
  /// Configures the regions to which to deploy and run a function.
  ///
  /// For a list of valid values see https://firebase.google.com/docs/functions/locations
  external FirebaseFunctions region(String region);

  /// Configures memory allocation and timeout for a function.
  external FirebaseFunctions runWith(RuntimeOptions options);

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

  /// Params namespace
  external Params get params;

  /// Constructor for Firebase [Event] objects.
  // ignore: non_constant_identifier_names
  external dynamic get Event;
}

/// The Cloud Function type for all non-HTTPS triggers.
///
/// This should be exported from your JavaScript file to define a Cloud Function.
/// This type is a special JavaScript function which takes a generic [Event]
/// object as its only argument.
typedef CloudFunction<T> = void Function(dynamic data, EventContext context);

/// The Cloud Function type for HTTPS triggers.
///
/// This should be exported from your JavaScript file to define a Cloud
/// Function. This type is a special JavaScript function which takes Express
/// Request and Response objects as its only arguments.
typedef HttpsFunction = void Function(
    IncomingMessage request, ServerResponse response);

/// The Functions interface for events that change state, such as
/// Realtime Database or Cloud Firestore `onWrite` and `onUpdate`.
@JS()
@anonymous
abstract class Change<T> {
  /// Represents the state after the event.
  external T get after;

  /// Represents the state prior to the event.
  external T get before;
}

@JS()
@anonymous
abstract class EventContextResource {
  external String get service;

  external String get name;
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
@JS()
@anonymous
abstract class EventContext {
  /// Authentication information for the user that triggered the function.
  ///
  /// For an unauthenticated user, this field is null. For event types that do
  /// not provide user information (all except Realtime Database) or for
  /// Firebase admin users, this field will not exist.
  external EventAuthInfo get auth;

  /// The level of permissions for a user.
  ///
  /// Valid values are: `ADMIN`, `USER`, `UNAUTHENTICATED` and `null`.
  external String get authType;

  /// The event’s unique identifier.
  external String get eventId;

  /// Type of event.
  external String get eventType;

  /// An object containing the values of the wildcards in the path parameter
  /// provided to the ref() method for a Realtime Database trigger.
  external dynamic get params;

  /// The resource that emitted the event.
  external EventContextResource get resource;

  /// Timestamp for the event as an RFC 3339 string.
  external String get timestamp;
}

@JS()
@anonymous
abstract class EventAuthInfo {
  external String get uid;

  external String get token;
}

@JS()
@anonymous
abstract class Config {}

@JS()
@anonymous
@staticInterop
abstract class HttpsFunctions {}

extension HttpsFunctionsExtV1 on HttpsFunctions {
  /// To send an error from an HTTPS Callable function to a client, throw an
  /// instance of this class from your handler function.
  ///
  /// Make sure to throw this exception at the top level of your function and
  /// not from within a callback, as that will not necessarily terminate the
  /// function with this exception.
  // ignore: non_constant_identifier_names
  external Object get HttpsError;

  /// Event handler which is run every time an HTTPS URL is hit.
  ///
  /// The event handler is called with Express Request and Response objects as its
  /// only arguments.
  external HttpsFunction onRequest(HttpRequestListener handler);

  external HttpsFunction onCall(
      dynamic Function(dynamic data, CallableContext context) handler);
}

extension HttpsFunctionsExtV2 on HttpsFunctions {
  /// Event handler which is run every time an HTTPS URL is hit.
  ///
  /// The event handler is called with Express Request and Response objects as its
  /// only arguments.
  external HttpsFunction onRequest(
      HttpsOptions options, HttpRequestListener handler);
}

@JS()
@anonymous
abstract class HttpsOptions {
  /// String or array string
  external Object? get region;

  /// Amount of memory to allocate to a function.
  /// "128MiB" | "256MiB" | "512MiB" | "1GiB" | "2GiB" | "4GiB" | "8GiB" | "16GiB" | "32GiB";
  /// external Object? get region;
  external String? get memory;

  /// Number of requests a function can serve at once.
  external int get concurrency;

  /// string | boolean | RegExp | Array<string | RegExp>
  ///
  /// If true, allows CORS on requests to this function. If this is a string or
  /// RegExp, allows requests from domains that match the provided value. If
  /// this is an Array, allows requests from domains matching at least one entry
  /// of the array. Defaults to true for https.CallableFunction and false
  /// otherwise.
  external Object? get cors;

  /// Timeout for the function in sections, possible values are 0 to 540. HTTPS functions can specify a higher timeout.
  external int get timeoutSeconds;

  /// Options
  external factory HttpsOptions(
      {Object? region,
      String? memory,
      int? concurrency,
      Object? cors,
      timeoutSeconds});
}

@JS()
@anonymous
@staticInterop
abstract class Params {}

extension ParamsExt on Params {
  /// A builtin param that resolves to the Cloud project ID associated with the project, without prompting the deployer.
  external Param get projectID;
}

@JS()
@anonymous
@staticInterop
abstract class Param {}

extension ParamExt on Param {
  /// A builtin param that resolves to the Cloud project ID associated with the project, without prompting the deployer.
  external String value();
  external dynamic get name;
}

@JS()
@anonymous
abstract class CallableContext {
  external CallableAuth? get auth;

  external String? get instanceIdToken;
}

@JS()
@anonymous
abstract class CallableAuth {
  external String? get uid;

  external admin.DecodedIdToken? get token;
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
  external CloudFunction onCreate(
      dynamic Function(admin.DataSnapshot data, EventContext context) handler);

  /// Event handler that fires every time data is deleted from Firebase Realtime
  /// Database.
  external CloudFunction onDelete(
      dynamic Function(admin.DataSnapshot data, EventContext context) handler);

  /// Event handler that fires every time data is updated in Firebase Realtime
  /// Database.
  external CloudFunction onUpdate(
      dynamic Function(Change<admin.DataSnapshot> data, EventContext context)
          handler);

  /// Event handler that fires every time a Firebase Realtime Database write of
  /// any kind (creation, update, or delete) occurs.
  external CloudFunction onWrite(
      dynamic Function(Change<admin.DataSnapshot> data, EventContext context)
          handler);
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
      dynamic Function(admin.DocumentSnapshot data, EventContext context)
          handler);

  /// Event handler that fires every time data is deleted from Cloud Firestore.
  external CloudFunction onDelete(
      dynamic Function(admin.DocumentSnapshot data, EventContext context)
          handler);

  /// Event handler that fires every time data is updated in Cloud Firestore.
  external CloudFunction onUpdate(
      dynamic Function(
              Change<admin.DocumentSnapshot> data, EventContext context)
          handler);

  /// Event handler that fires every time a Cloud Firestore write of any kind
  /// (creation, update, or delete) occurs.
  external CloudFunction onWrite(
      dynamic Function(
              Change<admin.DocumentSnapshot> data, EventContext context)
          handler);
}

@JS()
@anonymous
abstract class PubsubFunctions {
  /// Registers a function that triggers on Pubsub write events to
  /// the [topic].
  external TopicBuilder topic(String topic);

  /// Registers a function that triggers on Pubsub [schedule].
  external ScheduleBuilder schedule(String expression);
}

/// The Pubsub topic builder interface.
@JS()
@anonymous
abstract class TopicBuilder {
  /// Event handler that fires every time an event is publish in Pubsub.
  external CloudFunction onPublish(
      dynamic Function(Message data, EventContext context) handler);
}

/// The Pubsub schedule builder interface.
@JS()
@anonymous
abstract class ScheduleBuilder {
  /// Select timezone
  external ScheduleBuilder timeZone(String timeZone);

  /// Event handler that fires every time a schedule occurs.
  external CloudFunction onRun(dynamic Function(EventContext context) handler);
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
  /// Event handler sent only when a bucket has enabled object versioning.
  ///
  /// This event indicates that the live version of an object has become an
  /// archived version, either because it was archived or because it was
  /// overwritten by the upload of an object of the same name.
  external CloudFunction onArchive(
      void Function(ObjectMetadata data, EventContext context) handler);

  /// Event handler which fires every time a Google Cloud Storage deletion
  /// occurs.
  ///
  /// Sent when an object has been permanently deleted. This includes objects
  /// that are overwritten or are deleted as part of the bucket's lifecycle
  /// configuration. For buckets with object versioning enabled, this is not
  /// sent when an object is archived, even if archival occurs via the
  /// storage.objects.delete method.
  external CloudFunction onDelete(
      void Function(ObjectMetadata data, EventContext context) handler);

  /// Event handler which fires every time a Google Cloud Storage object
  /// creation occurs.
  ///
  /// Sent when a new object (or a new generation of an existing object) is
  /// successfully created in the bucket. This includes copying or rewriting an
  /// existing object. A failed upload does not trigger this event.
  external CloudFunction onFinalize(
      void Function(ObjectMetadata data, EventContext context) handler);

  /// Event handler which fires every time the metadata of an existing object
  /// changes.
  external CloudFunction onMetadataUpdate(
      void Function(ObjectMetadata data, EventContext context) handler);
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
  external String? get timeCreated;

  /// The deletion time of the object in RFC 3339 format. Returned only if this
  /// version of the object has been deleted.
  external String? get timeDeleted;

  /// The modification time of this object.
  external String? get updated;
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
  external CloudFunction onCreate(
      void Function(UserRecord data, EventContext context) handler);

  /// Event handler that fires every time a Firebase Authentication user is deleted.
  external CloudFunction onDelete(
      void Function(UserRecord data, EventContext context) handler);
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
