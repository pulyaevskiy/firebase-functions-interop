// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Interop library for Firebase Functions NodeJS SDK.
///
/// This library defines bindings to JavaScript APIs exposed by official Firebase
/// Functions library for NodeJS, therefore it can't be used on it's own. It
/// must be compiled to JavaScript and run under NodeJS runtime.
///
/// The main entry point is [FirebaseFunctions] class. Create an instance of this
/// class to access all the functionality of Firebase Functions.
library firebase_functions_interop;

export 'package:node_interop/node_interop.dart' show exports, console, Console;

export 'src/bindings.dart' show JsCloudFunction;
export 'src/core.dart';
export 'src/database.dart' hide createImpl;
export 'src/express.dart' show Request, Response;
