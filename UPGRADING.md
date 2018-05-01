## Upgrading from 1.0.0-dev.3.0 to 1.0.0-dev.4.0

Version `1.0.0-dev.4.0` of this library requires official Functions SDK version
`1.0.0` or higher. Versions `1.0.0-dev.3.0` and older were designed to work with
Functions SDK `0.8.x` branch.

Official migration guide is located here: https://firebase.google.com/docs/functions/beta-v1-diff.

> Note: any Firebase function created with older SDK version needs to be manually
> deleted from Gcloud console before it can be redeployed with the newer version.

Most of the changes in `dev.4.0` map directly to API changes in the official
SDK.

### `admin.config().firebase` field has been removed

If you used this field it is no longer available. If you'd like to access the
config values from your Firebase project, use environment variable
`FIREBASE_CONFIG` instead. In Dart this can be done using `node_io`
package:

```dart
import 'dart:convert'; // for json codec

import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:node_io/node_io.dart'; // to access Platform environment

Future someHttpsFunction(ExpressHttpRequest request) async {
  final config = new Map<String, String>.from(
    json.decode(Platform.environment['FIREBASE_CONFIG']));
  // ...do the rest...
  request.response.close();
}
```

### Background functions expect two arguments instead of one

The `event` parameter for asynchronous functions is obsolete. It has been
replaced by two new parameters: `data` and `context`.

Before `1.0.0-dev.4.0`:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['logAuth'] = FirebaseFunctions.auth.user().onCreate(logAuth);
}

/// Note that actual user record is wrapped by [AuthEvent] class.
void logAuth(AuthEvent event) {
  print(event.data.email);
}
```

After `1.0.0-dev.4.0`:

```dart
import 'package:firebase_functions_interop/firebase_functions_interop.dart';

void main() {
  functions['logAuth'] = FirebaseFunctions.auth.user().onCreate(logAuth);
}

/// Note that [data] argument contains actual changed user record.
void logAuth(UserRecord data, EventContext context) {
  print(data.email);
}
```

For details on each trigger type please refer to official migration guide: https://firebase.google.com/docs/functions/beta-v1-diff.
