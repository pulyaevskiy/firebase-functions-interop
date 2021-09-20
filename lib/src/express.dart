import 'package:node_interop/http.dart';
import 'package:node_interop/util.dart';
// ignore: implementation_imports
import 'package:tekartik_http_node/src/node/http_server.dart';

class ExpressHttpRequest extends NodeHttpRequest {
  ExpressHttpRequest(
      IncomingMessage nativeRequest, ServerResponse nativeResponse)
      : super(nativeRequest, nativeResponse);

  /// Decoded request body.
  dynamic get body {
    if (!hasProperty(nativeInstance, 'body')) return null;
    if (_body != null) return _body;
    _body = dartify(getProperty(nativeInstance, 'body'));
    return _body;
  }

  dynamic _body;
}
