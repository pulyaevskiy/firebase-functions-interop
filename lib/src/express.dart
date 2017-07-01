import 'package:node_interop/node_interop.dart';

import 'bindings.dart';

class Request implements JsRequest {
  final JsRequest _inner;

  Request(this._inner);

  @override
  String get method => _inner.method;

  @override
  Map<String, dynamic> get query => _query ??= jsObjectToMap(_inner.query);
  Map<String, dynamic> _query;
}

class Response implements JsResponse {
  final JsResponse _inner;

  Response(this._inner);

  @override
  void send(value) {
    _inner.send(value);
  }
}
