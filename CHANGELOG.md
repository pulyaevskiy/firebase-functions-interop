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
