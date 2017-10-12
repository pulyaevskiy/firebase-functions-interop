part of firebase_functions_interop.bindings;

@JS()
abstract class Database {
  external RefBuilder ref(String path);
  external dynamic get DeltaSnapshot;
}

@JS()
abstract class RefBuilder {
  external CloudFunction onWrite(Object handler(JsEvent event));
}

@JS()
abstract class DeltaSnapshot {
  external Reference get adminRef;
  external DeltaSnapshot get current;
  external String get key;
  external DeltaSnapshot get previous;
  external Reference get ref;
  external bool changed();
  external DeltaSnapshot child(String path);
  external bool exists();
  external bool hasChild(String path);
  external bool hasChildren();
  external int numChildren();
  external dynamic toJSON();
  external dynamic val();
}

@JS()
abstract class Reference {
  external Reference get parent;
  external Reference child(String path);
  external dynamic set(value, [void onComplete(error, undocumented)]);
}
