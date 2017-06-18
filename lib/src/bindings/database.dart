part of firebase_functions_interop.bindings;

@JS()
@anonymous
abstract class JsDatabase {
  external JsRefBuilder ref(String path);
}

@JS()
@anonymous
abstract class JsRefBuilder {
  external JsCloudFunction onWrite(Object handler(JsEvent event));
}

@JS()
@anonymous
abstract class JsDeltaSnapshot {
  external JsReference get adminRef;
  external JsDeltaSnapshot get current;
  external String get key;
  external JsDeltaSnapshot get previous;
  external JsReference get ref;
  external bool changed();
  external JsDeltaSnapshot child(String path);
  external bool exists();
  external bool hasChild(String path);
  external bool hasChildren();
  external int numChildren();
  external dynamic val();
}

@JS()
@anonymous
abstract class JsReference {
  external JsReference get parent;
  external JsReference child(String path);
  external dynamic set(value, void onComplete(error, undocumented));
}
