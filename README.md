[![Build Status](https://img.shields.io/travis-ci/pulyaevskiy/firebase-functions-interop.svg?branch=master&style=flat-square)](https://travis-ci.org/pulyaevskiy/firebase-functions-interop) [![Pub](https://img.shields.io/pub/v/firebase_functions_interop.svg?style=flat-square)](https://pub.dartlang.org/packages/firebase_functions_interop) [![Gitter](https://img.shields.io/badge/chat-on%20gitter-c73061.svg?style=flat-square)](https://gitter.im/pulyaevskiy/firebase-functions-interop)

Write Firebase Cloud functions in Dart, run in Node.js. This is an early
development preview, open-source project.

> Using `1.0.0-dev.*` version? See [UPGRADING.md][] for details on breaking changes and
> upgrade instructions.

[UPGRADING.md]: https://github.com/pulyaevskiy/firebase-functions-interop/blob/master/UPGRADING.md

## What is this?

`firebase_functions_interop` provides interoperability layer for
Firebase Functions Node.js SDK. Firebase functions written in Dart
using this library must be compiled to JavaScript and run in Node.js.
Luckily, a lot of interoperability details are handled by this library
and a collections of tools from Dart SDK.

Here is a minimalistic "Hello world" example of a HTTPS cloud function:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
}

void helloWorld(ExpressHttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}
```

## Status

Version 1.0.0 is considered stable though not feature complete.
Below is status report of already implemented functionality by namespace:

- [x] functions
- [x] functions.config
- [ ] functions.analytics
- [x] functions.auth
- [x] functions.firestore :fire:
- [x] functions.database
- [x] functions.https
- [x] functions.pubsub
- [x] functions.storage
- [ ] functions.remoteConfig

## Usage

> Make sure you have Firebase CLI installed as well as a Firebase account
> and a test app.
>
> See [Getting started](https://firebase.google.com/docs/functions/get-started)
> for more details.

### 1. Create Initial Project

```bash
$ mkdir myproject
$ cd myproject
$ firebase init functions
```

This creates `functions` subdirectory in your project's root which contains
standard Node.js package structure with `package.json` and `index.js` files.

### 2. Initialize Dart Project

Go to `functions` sub-folder and add a `pubspec.yaml` with following contents:

```yaml
name: myproject_functions
description: My project functions
version: 0.0.1

environment:
  sdk: '>=2.0.0-dev <3.0.0'

dependencies:
  # Firebase Functions bindings
  firebase_functions_interop: ^1.0.0

dev_dependencies:
  # Needed to compile Dart to valid Node.js module.
  build_runner: ^1.0.0
  build_node_compilers: ^0.2.0
```

Then run `pub get` to install dependencies.

### 3 Write a Basic Function

Create `functions/node/index.dart` and type in something like this:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
}

void helloWorld(ExpressHttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}
```

Copy-pasting also works.

### 4. Build your Function(s)

Version `1.0.0` of this library depends on Dart 2 and the new `build_runner`
package. Integration with dart2js and DDC compilers is provided by
`build_node_compilers` package which should already be in `dev_dependencies`
in `pubspec.yaml` (see step 2).

Create `functions/build.yaml` file with following contents:

```yaml
targets:
  $default:
    sources:
      - "node/**"
      - "lib/**"
    builders:
      build_node_compilers|entrypoint:
        generate_for:
        - node/**
        options:
          compiler: dart2js
          # List any dart2js specific args here, or omit it.
          dart2js_args:
          - --minify
```

> By default `build_runner` compiles with DDC which is not supported by this
> library at this point. Above configuration makes it compile Dart with dart2js.

To build run following:

```bash
$ cd functions
$ pub run build_runner build --output=build
```

### 5. Deploy

The result of `pub run` is located in `functions/build/node/index.dart.js`.

In your `functions/package.json`, set the `main` field to point to this file:

```json
{
    "...": "...",
    "main": "build/node/index.dart.js"
}
```

Alternatively, you can replace the default `index.js` with the built version:

```bash
$ cp functions/build/node/index.dart.js functions/index.js
```

Deploy using Firebase CLI:

```bash
$ firebase deploy --only functions
```

### 6. Test it

You can navigate to the new HTTPS function's URL printed out by the deploy command.
For the Realtime Database function, login to the Firebase Console and try
changing values under `/messages/{randomValue}/original`.

### 7. Scripts (optional)

You can use NPM scripts to simplify the work-flow of serving and deploying functions.

Update your `functions/package.json` to be like so:

```json
{
	"...": "...",
    "scripts": {
         "build": "pub run build_runner build --output=build",
         "watch": "pub run build_runner watch --output=build",

        "preserve": "npm run build",
        "serve": "firebase serve --only functions",

        "predeploy": "npm run build",
        "deploy": "firebase deploy --only functions",

        "preshell": "npm run build",
        "shell": "firebase experimental:functions:shell",

        "...": "..."
    }
}
```

## Examples


### HTTPS Function

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
}

void helloWorld(ExpressHttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}
```

### Realtime Database Function

```dart
void main() {
  functions['makeUppercase'] = functions.database
      .ref('/messages/{messageId}/original')
      .onWrite(makeUppercase);
}

FutureOr<void> makeUppercase(DatabaseEvent<String> event) {
  var original = event.data.val();
  print('Uppercasing $original');
  return event.data.ref.parent.child('uppercase').setValue(uppercase);
}
```

### Firestore Function

```dart
void main() {
  functions['makeNamesUppercase'] = functions.firestore
      .document('/users/{userId}').onWrite(makeNamesUppercase)
}

FutureOr<void> makeNamesUppercase(FirestoreEvent event) {
  if(event.data.data.getString("uppercasedName") == null) {
    var original = event.data.data.getString("name");
    print('Uppercasing $original');

    UpdateData newData = new UpdateData();
    newData.setString("uppercasedName", original);

    return event.data.reference.updateData(newData);
  }
}
```

### Pubsub Functions

```dart
void main() {
  functions['logPubsub'] = functions.pubsub.topic('my-topic').onPublish(logPubsub);
}

void logPubsub(PubsubEvent event) {
  print(event.data.json["name"]);
}
```

### Storage Functions

```dart
void main() {
  functions['logStorage'] = functions.storage.object().onChange(logStorage);
}

void logStorage (StorageEvent event){
  print(event.data.name);
}
```

### Auth Functions

```dart
void main() {
  functions['logAuth'] = functions.auth.user().onCreate(logAuth);
}

void logAuth(AuthEvent event) {
  print(event.data.email);
}
```

## Configuration

Firebase SDK provides a way to set and access environment variables from
your Firebase functions.

Environment variables are set using Firebase CLI, e.g.:

```bash
firebase functions:config:set some_service.api_key="secret" some_service.url="https://api.example.com"
```

For more details see https://firebase.google.com/docs/functions/config-env.

To read these values in a Firebase function use `functions.config`.

Below example also uses [node_http][] package which provides a HTTP client
powered by Node.js I/O.

[node_http]: https://pub.dartlang.org/packages/node_http

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:node_http/node_http.dart' as http;

void main() {
  functions['helloWorld'] = functions.https.onRequest(helloWorld);
}

void helloWorld(ExpressHttpRequest request) async {
  /// fetch env configuration
  final config = functions.config;
  final String serviceKey = config.get('someservice.key');
  final String serviceUrl = config.get('someservice.url');
  /// `http.get()` function is exposed by the `node_http` package.
  var response = await http.get("$serviceUrl?apiKey=$serviceKey");
  // do something with the response, e.g. forward response body to the client:
  request.response.write(response.body);
  request.response.close();
}
```

## HTTPS Functions Details

Firebase uses the Express.js web framework for HTTPS functions with `body-parser`
middleware enabled by default ([documentation](https://firebase.google.com/docs/functions/http-events#read_values_from_the_request)).

The `ExpressHttpRequest` exposed by this library extends standard `dart:io`
`HttpRequest` interface, which means it is also a stream of bytes. However
if `body-parser` middleware already decoded request body then listening for
data on the request would hang since it's already been consumed. Use
`ExpressHttpRequest.body` field to get decoded request body in this case.


## Features and Bugs

Please file feature requests and bugs at the [issue tracker](https://github.com/pulyaevskiy/firebase-functions-interop/issues/new).

See [the development file](DEVELOPMENT.md) for instructions on running the test suite.
