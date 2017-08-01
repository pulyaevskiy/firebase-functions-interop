@JS()
library firebase_functions_interop.bindings;

import 'package:js/js.dart';
import 'package:node_interop/node_interop.dart';

part 'bindings/database.dart';
part 'bindings/express.dart';
part 'bindings/https.dart';

JsFirebaseFunctions requireFirebaseFunctions() => require('firebase-functions');

@JS()
@anonymous
abstract class JsFirebaseFunctions {
  external JsHttps get https;
  external JsDatabase get database;
}

@JS()
@anonymous
abstract class JsCloudFunction {}

@JS()
@anonymous
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
