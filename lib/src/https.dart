part of firebase_functions_interop;

/// To send an error from an HTTPS Callable function to a client, throw an
/// instance of this class from your handler function.
///
/// Make sure to throw this exception at the top level of your function and
/// not from within a callback, as that will not necessarily terminate the
/// function with this exception.
class HttpsError {
  /// The operation was cancelled (typically by the caller).
  static const String canceled = 'cancelled';

  ///  Unknown error or an error from a different error domain.
  static const String unknown = 'unknown';

  /// Client specified an invalid argument.
  ///
  /// Note that this differs from [failedPrecondition]. [invalidArgument]
  /// indicates arguments that are problematic regardless of the state of the
  /// system (e.g. an invalid field name).
  static const String invalidArgument = 'invalid-argument';

  /// Deadline expired before operation could complete.
  ///
  /// For operations that change the state of the system, this error may be
  /// returned even if the operation has completed successfully. For example,
  /// a successful response from a server could have been delayed long enough
  /// for the deadline to expire.
  static const String deadlineExceeded = 'deadline-exceeded';

  /// Some requested document was not found.
  static const String notFound = 'not-found';

  /// Some document that we attempted to create already exists.
  static const String alreadyExists = 'already-exists';

  /// The caller does not have permission to execute the specified operation.
  static const String permissionDenied = 'permission-denied';

  /// Some resource has been exhausted, perhaps a per-user quota, or perhaps
  /// the entire file system is out of space.
  static const String resourceExhausted = 'resource-exhausted';

  /// Operation was rejected because the system is not in a state required for
  /// the operation`s execution.
  static const String failedPrecondition = 'failed-precondition';

  /// The operation was aborted, typically due to a concurrency issue like
  /// transaction aborts, etc.
  static const String aborted = 'aborted';

  /// Operation was attempted past the valid range.
  static const String outOfRange = 'out-of-range';

  /// Operation is not implemented or not supported/enabled.
  static const String unimplemented = 'unimplemented';

  /// Internal errors. Means some invariants expected by underlying system has
  /// been broken.
  ///
  /// If you see one of these errors, something is very broken.
  static const String internal = 'internal';

  /// The service is currently unavailable.
  ///
  /// This is most likely a transient condition and may be corrected by
  /// retrying with a backoff.
  static const String unavailable = 'unavailable';

  /// Unrecoverable data loss or corruption.
  static const String dataLoss = 'data-loss';

  /// The request does not have valid authentication credentials for the
  /// operation.
  static const String unauthenticated = 'unauthenticated';

  HttpsError(this.code, this.message, this.details);

  /// A status error code to include in the response.
  final String code;

  /// A message string to be included in the response body to the client.
  final String message;

  /// An object to include in the "details" field of the response body.
  ///
  /// As with the data returned from a callable HTTPS handler, this can be
  /// `null` or any JSON-encodable object (`String`, `int`, `List` or `Map`
  /// containing primitive types).
  final dynamic details;

  dynamic _toJsHttpsError() {
    return callConstructor(
        _js.https.HttpsError, [code, message, jsify(details)]);
  }
}

class CallableContext {
  /// The uid from decoding and verifying a Firebase Auth ID token. Value may
  /// be `null`.
  final String authUid;

  /// The result of decoding and verifying a Firebase Auth ID token. Value may
  /// be `null`.
  final DecodedIdToken authToken;

  /// An unverified token for a Firebase Instance ID.
  final String instanceIdToken;

  CallableContext(this.authUid, this.authToken, this.instanceIdToken);
}

/// HTTPS functions namespace.
class HttpsFunctions {
  const HttpsFunctions._();

  /// Event [handler] which is run every time an HTTPS URL is hit.
  ///
  /// Returns a [js.HttpsFunction] which can be exported.
  ///
  /// The event handler is called with single [request] argument, instance
  /// of [ExpressHttpRequest]. This object acts as a
  /// proxy to JavaScript request and response objects.
  js.HttpsFunction onRequest(void handler(ExpressHttpRequest request)) {
    void jsHandler(IncomingMessage request, ServerResponse response) {
      var requestProxy = new ExpressHttpRequest(request, response);
      handler(requestProxy);
    }

    return _js.https.onRequest(allowInterop(jsHandler));
  }

  /// Event handler which is run every time an HTTPS Callable function is called
  /// from a Firebase client SDK.
  ///
  /// The event handler is called with the data sent from the client, and with
  /// a [CallableContext] containing metadata about the request.
  ///
  /// The value returned from this handler, either as a [Future] or returned
  /// directly, is sent back to the client.
  ///
  /// If this handler throws (or returns a [Future] which completes with) an
  /// instance of [HttpsError], then the error details are sent back to the
  /// client. If this handler throws any other kind of error, then the client
  /// receives an error of type [HttpsError.internal].
  js.HttpsFunction onCall(
      FutureOr<dynamic> handler(dynamic data, CallableContext context)) {
    dynamic jsHandler(data, js.CallableContext context) {
      var auth = context.auth;
      var ctx = new CallableContext(
        auth?.uid,
        auth?.token,
        context.instanceIdToken,
      );
      try {
        var result = handler(dartify(data), ctx);

        if (result is Future) {
          final future = result.then(_tryJsify).catchError((error) {
            if (error is HttpsError) {
              throw error._toJsHttpsError();
            } else
              throw error;
          });
          return futureToPromise(future);
        } else {
          return _tryJsify(result);
        }
      } on HttpsError catch (error) {
        throw error._toJsHttpsError();
      }
    }

    return _js.https.onCall(allowInterop(jsHandler));
  }

  dynamic _tryJsify(data) {
    try {
      return jsify(data);
    } on ArgumentError {
      console.error('Response cannot be encoded.', data.toString(), data);
      throw HttpsError(
        HttpsError.internal,
        'Invalid response, check logs for details',
        data.toString(),
      );
    }
  }
}
