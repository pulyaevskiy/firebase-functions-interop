// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@JS()
library firebase_functions_interop.bindings;

import 'package:js/js.dart';
import 'package:node_interop/node_interop.dart';

final FirebaseFunctions requireFirebaseFunctions =
    require('firebase-functions');

@JS()
abstract class CloudFunction {}

@JS()
abstract class Event<T> {
  external T get data;
  external String get eventId;
  external String get eventType;
  external dynamic get params;
  external String get resource;
  external dynamic get timestamp;
}

@JS()
abstract class FirebaseFunctions {
  external Https get https;
  external Database get database;
  external dynamic config();
}

@JS()
abstract class Https {
  external CloudFunction onRequest(HttpRequestListener handler);
}

/// Namespace for Firebase Realtime Database functions.
@JS()
abstract class Database {
  /// Registers a function that triggers on Firebase Realtime Database write
  /// events at specified [path].
  external RefBuilder ref(String path);

  /// Reference to [DeltaSnapshot] constructor function.
  external dynamic get DeltaSnapshot;
}

/// The Firebase Realtime Database reference builder interface.
@JS()
abstract class RefBuilder {
  /// Event handler that fires every time new data is created in Firebase
  /// Realtime Database.
  external CloudFunction onCreate(Object handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time data is deleted from Firebase Realtime
  /// Database.
  external CloudFunction onDelete(Object handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time data is updated in Firebase Realtime
  /// Database.
  external CloudFunction onUpdate(Object handler(Event<DeltaSnapshot> event));

  /// Event handler that fires every time a Firebase Realtime Database write of
  /// any kind (creation, update, or delete) occurs.
  external CloudFunction onWrite(Object handler(Event<DeltaSnapshot> event));
}

/// Interface representing a Firebase Realtime Database delta snapshot.
@JS()
abstract class DeltaSnapshot {
  external Reference get adminRef;
  external DeltaSnapshot get current;
  external String get key;
  external DeltaSnapshot get previous;
  external Reference get ref;
  external bool changed();
  external DeltaSnapshot child(String path);
  external bool exists();
  external bool hasChild(String path);
  external bool hasChildren();
  external int numChildren();
  external dynamic toJSON();
  external dynamic val();
}

@JS()
abstract class Reference {
  external Reference get parent;
  external Reference child(String path);
  external dynamic set(value, [void onComplete(error, undocumented)]);
}

/// Namespace for Cloud Firestore Functions
@JS()
abstract class Firestore {
  /// Registers a function that triggers on Cloud Firestore write events to
  /// the [document].
  external DocumentBuilder document(String document);
}

/// The Cloud Firestore document builder interface.
@JS()
abstract class DocumentBuilder {
  external CloudFunction onCreate(handler(Event<DocumentDeltaSnapshot> event));
  external CloudFunction onDelete(handler(Event<DocumentDeltaSnapshot> event));
  external CloudFunction onUpdate(handler(Event<DocumentDeltaSnapshot> event));
  external CloudFunction onWrite(handler(Event<DocumentDeltaSnapshot> event));
}

/// Interface representing a Cloud Firestore document delta snapshot.
@JS()
abstract class DocumentDeltaSnapshot {
  /// The date the document was created, formatted as a UTC string.
  external String get createTime;

  /// Returns `true` if this DocumentDeltaSnapshot contains any data.
  external bool get exists;

  /// Extracts a document ID from a DocumentDeltaSnapshot.
  external String get id;

  /// Gets the previous state of this document, from before the triggering write
  /// event.
  external DocumentDeltaSnapshot get previous;

  /// The last time the document was read, formatted as a UTC string.
  external String get readTime;

  /// Returns a DocumentReference to the database location where the triggering
  /// write occurred. This DocumentReference has admin privileges.
  // TODO: update firebase_admin with DocumentReference
  external dynamic get ref;

  /// The last update time for the document, formatted as a UTC string.
  external String get updateTime;

  /// Returns the data fields in their state after the triggering write event
  /// has occurred.
  external dynamic data();

  /// Gets the value for a given key.
  external dynamic get(key);
}

@JS("JSON.stringify")
external String stringify(obj); // TODO: Move to node_interop
