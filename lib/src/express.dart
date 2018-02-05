import 'package:node_interop/http.dart';
import 'package:node_interop/util.dart';
import 'package:node_io/node_io.dart';

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
