@JS()
library setup;

import 'package:node_interop/node_interop.dart';
import 'package:node_interop/fs.dart';
import 'package:js/js.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

const platform = const NodePlatform();
const fs = const NodeFileSystem();
final Map<String, String> env = platform.environment;

App initFirebaseApp() {
  if (!env.containsKey('FIREBASE_SERVICE_ACCOUNT_FILEPATH') ||
      !env.containsKey('FIREBASE_DATABASE_URL') ||
      !env.containsKey('FIREBASE_HTTP_BASE_URL')) {
    throw new StateError("Environment variables not set.");
  }
  _installNodeModules();
  var admin = new FirebaseAdmin();
  return admin.initializeApp(new AppOptions(
    credential: admin.credential.cert(env['FIREBASE_SERVICE_ACCOUNT_FILEPATH']),
    databaseUrl: env['FIREBASE_DATABASE_URL'],
  ));
}

void _installNodeModules() {
  var segments = platform.script.pathSegments.toList();
  var cwd = fs.path.dirname(platform.script.path);
  segments
    ..removeLast()
    ..add('package.json');
  var jsFilepath = fs.path.separator + fs.path.joinAll(segments);
  var file = fs.file(jsFilepath);
  file.writeAsStringSync(_kPackageJson);

  ChildProcess childProcess = require('child_process');
  print('Installing node modules');
  childProcess.execSync('npm install', new ExecOptions(cwd: cwd));
}

const _kPackageJson = '''
{
    "name": "test",
    "description": "Test",
    "dependencies": {
        "firebase-admin": "~4.2.1"
    },
    "private": true
}
''';

@JS()
@anonymous
abstract class ChildProcess {
  external execSync(String command, [options]);
}

@JS()
@anonymous
abstract class ExecOptions {
  external String get cwd;
  external factory ExecOptions({String cwd});
}
