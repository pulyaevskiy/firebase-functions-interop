import 'bindings.dart' as js;

/// Namespace for Firebase Authentication functions.
class Params {
  final js.FirebaseFunctions _functions;

  Params(this._functions);

  /// projectId
  String get projectId {
    return _functions.params.projectID.value();
  }
}
