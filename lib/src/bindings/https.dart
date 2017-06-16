part of firebase_functions_interop.bindings;

typedef void JsRequestHandler(JsRequest request, JsResponse response);

@JS()
@anonymous
abstract class JsHttps {
  external JsCloudFunction onRequest(JsRequestHandler handler);
}
