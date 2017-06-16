part of firebase_functions_interop.bindings;

@JS()
abstract class JsRequest {
  external String get method;
  external dynamic get query;
}

@JS()
abstract class JsResponse {
  external void send(value);
}
