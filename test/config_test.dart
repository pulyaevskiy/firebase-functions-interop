// Copyright (c) 2017, Anatoly Pulyaevskiy. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

@JS()
@TestOn('node')
library config_test;

import 'dart:js';

import 'package:firebase_functions_interop/firebase_functions_interop.dart';
import 'package:js/js.dart';
import 'package:node_interop/fs.dart';
import 'package:node_interop/node_interop.dart';
import 'package:node_interop/test.dart';
import 'package:test/test.dart';

const fs = const NodeFileSystem();

const configFixture = '''

function Apple(color) {
  this.color = color;
}

exports.data = {
  "example_int": 123,
  "example_string": "Firebase",
  "example_bool": true,
  "example": {
    "multi_key": "nested_value"
  },
  "no": "unexpected_value",
  "firebase": new Apple("red")
}
''';

void main() {
  createFile('config_fixture.js', configFixture);

  group('Config', () {
    ConfigFixture jsConf;
    setUpAll(() {
      var segments = node.platform.script.pathSegments.toList();
      segments
        ..removeLast()
        ..add('config_fixture.js');
      var jsFilepath = fs.path.separator + fs.path.joinAll(segments);
      var file = fs.file(jsFilepath);
      file.writeAsStringSync(configFixture);

      jsConf = require('./config_fixture');
    });

    test('JS types converted to Dart', () {
      var conf = new Config();
      expect(conf.get("example_int"), 123);
      expect(conf.get("example_string"), "Firebase");
      expect(conf.get("example_bool"), isTrue);
      expect(conf.get("example.multi_key"), "nested_value");
    });

    test('non-existing keys resolve to null', () {
      var conf = new Config();
      expect(conf.get("no_such_key"), isNull);
      expect(conf.get("no.such.nested.key"), isNull);
    });

    test('firebase object is returned as a map', () {
      var conf = new Config();
      expect(conf.get("firebase"), isMap);
    });
  });
}

@JS()
@anonymous
abstract class ConfigFixture {
  external JsObject get data;
}
