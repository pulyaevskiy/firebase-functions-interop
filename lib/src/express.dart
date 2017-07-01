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

  @override
  Map<String, dynamic> get headers =>
      _headers ??= jsObjectToMap(_inner.headers);
  Map<String, dynamic> _headers;

  @override
  String get url => _inner.url;

  @override
  String get originalUrl => _inner.originalUrl;
}

class Response implements JsResponse {
  final JsResponse _inner;

  Response(this._inner);

  @override
  void send(value) {
    _inner.send(value);
  }

  @override
  void setHeader(String name, String value) => _inner.setHeader(name, value);
}
