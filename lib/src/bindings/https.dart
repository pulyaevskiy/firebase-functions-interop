part of firebase_functions_interop.bindings;

@JS()
abstract class Https {
  external CloudFunction onRequest(HttpRequestListener handler);
}
