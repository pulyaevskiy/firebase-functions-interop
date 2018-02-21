#!/bin/bash

set -e

pub get

cd functions
pub get
npm install
pub run build_runner build \
    --define="build_node_compilers|entrypoint=compiler=dart2js" \
    --define="build_node_compilers|entrypoint=dart2js_args=[\"--checked\"]" \
    --output=build/

if [ -z "$TRAVIS" ]; then
    echo "Provisioning functions for local environment"
    # The only way I know to delete existing functions is to deploy empty module:
    cp build/node/clear.dart.js index.js
    firebase deploy --only functions

    firebase functions:config:set someservice.key=123456 someservice.url="https://example.com" someservice.enabled=true

    # Create new functions
    cp build/node/index.dart.js index.js
    firebase deploy --only functions
else
    echo "Provisioning functions for Travis build environment"
    echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$FIREBASE_SERVICE_ACCOUNT_FILEPATH"
    # The only way I know to delete existing functions is to deploy empty module:
    cp build/node/clear.dart.js index.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID"

    firebase functions:config:set --token="$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID" someservice.key=123456 someservice.url="https://example.com" someservice.enabled=true

    # Create new functions
    cp build/node/index.dart.js index.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID"
fi
