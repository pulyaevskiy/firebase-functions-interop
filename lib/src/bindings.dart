@JS()
library firebase_functions_interop.bindings;

import 'dart:js';
import 'package:js/js.dart';
import 'package:node_interop/node_interop.dart';

part 'bindings/database.dart';
part 'bindings/https.dart';

final FirebaseFunctions requireFirebaseFunctions =
    require('firebase-functions');

@JS()
abstract class FirebaseFunctions {
  external Https get https;
  external Database get database;
  external JsObject config();
}

@JS()
abstract class CloudFunction {}

@JS()
abstract class JsEvent {
  external dynamic get data;
  external String get eventId;
  external String get eventType;
  external dynamic get params;
  external String get resource;
  external dynamic get timestamp;
}

@JS("JSON.stringify")
external String stringify(obj);
