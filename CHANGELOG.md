## 1.0.0-dev.10.0

- Breaking change: upgraded to JS module firebase-functions `v2.0.5` which introduced breaking
    changes in `DocumentSnapshot.createTime`, `DocumentSnapshot.updateTime`
- Upgraded to `firebase_admin_interop` v1.0.0-dev.20.0 which also introduced breaking changes
    around Timestamps. See changelog and readme in `firebase_admin_interop` for more details.

## 1.0.0-dev.9.0

- Fixed: EventContext.resource type changed from String to object.
- Misc: removed strong-mode analyzer option from test functions.

## 1.0.0-dev.8.0

- Fixed analysis warnings and declared support for Dart 2 stable.

## 1.0.0-dev.7.0

- Internal: upgraded example functions to use latest build_runner.
- Internal: strong mode fix for tests setup script.

## 1.0.0-dev.6.0

- Fixed: strong mode issue in Firestore `EventContext` after deploying
    tests with `--preview-dart-2` instead of `--checked`.
- Fixed: strong mode issue in Database event handlers instantiating
    `DataSnapshot` with proper generic type argument.

## 1.0.0-dev.5.0

- Added: `FirebaseFunctions.https.onCall` as well as `HttpsError` and
    `CallableContext`.

## 1.0.0-dev.4.0

- Breaking: Upgraded to Functions SDK 1.0.1 and Admin SDK 5.12.0
  Official migration guide is located here: https://firebase.google.com/docs/functions/beta-v1-diff
  Changes in this library are identical and slightly adapted to Dart
  semantics:
  * `admin.config().firebase` field has been removed
  * Background functions (that is everything except HTTPS) now
    expect two arguments `data` and `context` instead of single `event`
    argument.
  * See `UPGRADING.md` for more details and instructions. Also check updated
    examples in `example/`folder.

## 1.0.0-dev.3.0

- Added: Pubsub (#10), Storage (#12) and Auth (#17) triggers support.

## 1.0.0-dev.2.0

- Fixed: expose Firestore functions namespace in `FirebaseFunctions.firestore` (#8).
- Other: update readme and development docs (#8).

## 1.0.0-dev.1.0

- Depends on Dart SDK >= 2.0.0-dev.19.0.
- Depends on firebase_admin_interop >= 1.0.0-dev.1.0 (as well as node_* packages).
- Breaking: Removed built_value support.
- Added Firestore triggers support.
- Deprecated `firebaseFunctions`, to be replaced with shorter `functions`.
- Breaking: firebaseFunctions.https is now `static const`. Use `FirebaseFunctions.https`.
- Breaking: firebaseFunctions.database is now `static const`. Use `FirebaseFunctions.database`.

## 0.1.0-beta.3

- Fixed dependency constraints

## 0.1.0-beta.2

- Fixed: RefBuilder onCreate, onUpdate and onDelete were subscribing to JS onWrite (see #5)

## 0.1.0-beta.1

This version marks first attempt to stabilize API layer provided
by this library, which (ironically) means there _are_ some breaking
changes.

- Updated for `node_interop: 0.1.0-beta`.
- Updated for `firebase_admin_interop: 0.1.0-beta`.
- Removed `stringify` from bindings, use `jsonStringify` from
  node_interop instead (available since `0.1.0-beta.6`).
- Reorganized bindings in single file.
- Finalized bindings for HTTPS and Realtime Database functions.
- Added support for `built_value` serializers in Realtime Database
  functions
- HTTPS functions `onRequest` method now accepts handler function with
  single parameter of type `HttpRequest` (from `node_interop/http`).
  This request is fully compatible with "dart:io" and acts mostly
  as a proxy to JS native request and response objects. This should
  also make it easier to build integrations with Dart server-side web
  frameworks.
- Gitter: [https://gitter.im/pulyaevskiy/firebase-functions-interop](https://gitter.im/pulyaevskiy/firebase-functions-interop)

## 0.0.4

- Added `<0.1.0` constraint on `node_interop` dependency.

## 0.0.3

- Added `toJson` to `DeltaSnapshot`.
- Added top-level `firebaseFunctions` getter.
- Deprecated `FirebaseFunctions` constructor. Use `firebaseFunctions` instead.
- Implemented `firebaseFunctions.config()`.
- Added `DEVELOPMENT.md` docs.

## 0.0.2

- Added generics to Event class (#3)
- Added basic integration testing infrastructure
- Minor dartdoc updates

## 0.0.1

- Initial version
