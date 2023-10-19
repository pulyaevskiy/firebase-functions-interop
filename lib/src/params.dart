import 'bindings.dart' as js;

/// Namespace for Firebase Authentication functions.
class Params {
  final js.Params _params;

  Params._(this._params);

  /// projectId
  String get projectId => _params.projectID;
}
