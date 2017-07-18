@TestOn('node')
import 'package:test/test.dart';
import 'setup_admin.dart';

void main() {
  group('DatabaseFunctions', () {
    var app = initFirebaseApp();

    setUp(() async {
      var ref = app.database().ref('/messages/test/uppercase');
      await ref.set(null);
      var data = await ref.once('value');
      while (data.val() != null) {
        data = await ref.once('value');
      }
    });

    tearDownAll(() async {
      await app.delete();
    });

    test('happy path integration test', () async {
      var ref = app.database().ref('/messages/test/original');
      var value = 'lowercase' + (new DateTime.now().toIso8601String());
      await ref.set(value);
      var ucRef = app.database().ref('/messages/test/uppercase');
      var data = await ucRef.once('value');
      while (data.val() == null) {
        data = await ucRef.once('value');
      }
      expect(data.val(), value.toUpperCase());
    });
  }, timeout: new Timeout(new Duration(seconds: 10)));
}
