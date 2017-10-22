# Firebase Functions Interop Library for Dart

[![Build Status](https://travis-ci.org/pulyaevskiy/firebase-functions-interop.svg?branch=master)](https://travis-ci.org/pulyaevskiy/firebase-functions-interop)

Write Firebase Cloud functions in Dart, run in NodeJS. This is an early
preview, alpha open-source project.

* [What is this?](#what-is-this?)
* [Status](#status)
* [Usage](#usage)
* [Configuration](#configuration)

## What is this?

`firebase_functions_interop` provides interoperability layer for
Firebase Functions NodeJS client. Firebase functions written in Dart
using this library must be compiled to JavaScript and run in NodeJS.
Luckily, a lot of interoperability details are handled by this library
and a collections of tools from Dart SDK.

Here is a minimalistic "Hello world" example of a HTTP cloud function:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);
}

void helloWorld(HttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}
```

## Status

This is a early preview, alpha version which is not feature complete.

Below is status report of already implemented functionality by
namespace:

- [x] functions
- [x] functions.config
- [ ] functions.analytics
- [ ] functions.auth
- [ ] functions.firestore :fire: (bindings only at this point)
- [x] functions.database
- [x] functions.https
- [ ] functions.pubsub
- [ ] functions.storage


## Usage

> Make sure you have Firebase CLI installed as well as a Firebase account
> and a test app.
> See [Getting started](https://firebase.google.com/docs/functions/get-started)
> for more details.

### 1. Create a new project directory and initialize functions:

```bash
$ mkdir myproject
$ cd myproject
$ firebase init functions
```

This creates `functions` subdirectory in your project's root which contains
standard NodeJS package structure with `package.json` and `index.js` files.

### 2. Initialize Dart project

Go to `functions` subfolder and add `pubspec.yaml` with following contents:

```yaml
name: myproject_functions
description: My project functions
version: 0.0.1

environment:
  sdk: '>=1.20.1 <2.0.0'

dependencies:
  # Firebase Functions bindings
  firebase_functions_interop: ^0.1.0-beta.1
  # Node bindings required to compile a nice-looking JS file for Node.
  # Also provides access to globals like `require` and `exports`.
  node_interop: ^0.1.0-beta.6

transformers:
  - $dart2js
  - node_interop # This transformer must go after $dart2js
```

Then run `pub get` to install dependencies.

### 3.1 Write a Web function

Create `node/index.dart` and type in something like this:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);
}

void helloWorld(HttpRequest request) {
  request.response.writeln('Hello world');
  request.response.close();
}
```

Copy-pasting also works.

### 3.2 Write a Realtime Database Function (optional)

Update `node/index.dart` with following:

```dart
void main() {
  // ...Add after registration of helloWorld function:
  firebaseFunctions['makeUppercase'] = firebaseFunctions.database
        .ref('/messages/{messageId}/original')
        .onWrite(makeUppercase);
}

FutureOr<Null> makeUppercase(DatabaseEvent<String> event) {
  var original = event.data.val();
  print('Uppercasing $original');
  return event.data.ref.parent.child('uppercase').setValue(uppercase);
}
```

### 4. Build your function(s)

Building functions is as simple as running `pub build`. Note that Pub by
default assumes a "web" project and only builds `web/` folder so we need
to explicitly tell it about `node/`:

```bash
$ pub build node/
```

### 5. Copy and deploy

The result of `pub build` is located in `build/node/index.dart.js`. Replace
default `index.js` with the built version:

```bash
$ cp build/node/index.dart.js index.js
```

Deploy using Firebase CLI:

```bash
$ firebase deploy --only functions
```

### 6. Test it

You can navigate to the new HTTPS function's URL printed out by the deploy command.
For the Realtime Database function, login to the Firebase Console and try
changing values under `/messages/{randomValue}/original`.

## Configuration

Firebase SDK provides a way to set and access environment variables from
your Firebase functions.

Environment variables are set using Firebase CLI, e.g.:

```bash
firebase functions:config:set some_service.api_key="secret" some_service.url="https://api.example.com"
```

For more details see https://firebase.google.com/docs/functions/config-env.

To read these values in a Firebase function use `firebaseFunctions.config`:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';
// Import 'node_interop/http' as it provides convenient HTTP client
// implementation which uses Node IO system.
import 'package:node_interop/http.dart';

void main() {
  firebaseFunctions['helloWorld'] =
      firebaseFunctions.https.onRequest(helloWorld);
}

void helloWorld(HttpRequest request) async {
  /// fetch env configuration
  var config = firebaseFunctions.config;
  var serviceKey = config.get('someservice.key');
  var serviceUrl = config.get('someservice.url');
  /// use HTTP client to make calls to external systems:
  var http = new NodeClient();
  var response = await http.get("$serviceUrl?apiKey=$serviceKey");
  // do something with the response, e.g. forward response body to the client:
  request.response.write(response.body);
  request.response.close();
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/pulyaevskiy/firebase-functions-interop/issues/new
