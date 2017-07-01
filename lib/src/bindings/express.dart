part of firebase_functions_interop.bindings;

@JS()
abstract class JsRequest {
  external String get method;
  external dynamic get query;
  external dynamic get headers;
}

@JS()
abstract class JsResponse {
  external void setHeader(String name, String value);
  external void send(value);
}
