@JS()
library setup;

import 'package:node_interop/node_interop.dart';
import 'package:node_interop/fs.dart';
import 'package:js/js.dart';
import 'package:firebase_admin_interop/firebase_admin_interop.dart';

final platform = new NodePlatform();
final Map<String, String> env = platform.environment;

App initFirebaseApp() {
  installNodeModules();

  var admin = new FirebaseAdmin();
  return admin.initializeApp(new AppOptions(
    credential: admin.credential.cert(appCredentials),
    databaseUrl: env['FIREBASE_DATABASE_URL'],
  ));
}

void installNodeModules() {
  var fs = new NodeFileSystem();
  var platform = new NodePlatform();
  var segments = platform.script.pathSegments.toList();
  var cwd = fs.path.dirname(platform.script.path);
  segments
    ..removeLast()
    ..add('package.json');
  var jsFilepath = fs.path.separator + fs.path.joinAll(segments);
  var file = fs.file(jsFilepath);
  file.writeAsStringSync(packageJson);

  ChildProcess childProcess = require('child_process');
  print('Installing node modules');
  childProcess.execSync('npm install', new ExecOptions(cwd: cwd));
}

Map<String, String> get appCredentials {
  return {
    'project_id': env['FIREBASE_PROJECT_ID'],
    'client_email': env['FIREBASE_CLIENT_EMAIL'],
    'private_key': env['FIREBASE_PRIVATE_KEY'].replaceAll(r'\n', '\n'),
  };
}

const packageJson = '''
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
