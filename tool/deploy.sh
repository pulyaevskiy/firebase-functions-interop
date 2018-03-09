#!/bin/bash

set -e

pub get

cd functions
pub get
npm install
npm run build

if [ -z "$TRAVIS" ]; then
    echo "Provisioning functions for local environment"
    # The only way I know to delete existing functions is to deploy empty module:
    cp build/node/index.dart.js build/node/index.dart.js.temp
    cp build/node/clear.dart.js build/node/index.dart.js
    firebase deploy --only functions

    firebase functions:config:set someservice.key=123456 someservice.url="https://example.com" someservice.enabled=true

    # Create new functions
    cp build/node/index.dart.js.temp build/node/index.dart.js
    firebase deploy --only functions
else
    echo "Provisioning functions for Travis build environment"
    echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$FIREBASE_SERVICE_ACCOUNT_FILEPATH"

    # Ensure gcloud sdk is present
    gcloud version || true
    if [ ! -d "$HOME/google-cloud-sdk/bin" ]; then rm -rf $HOME/google-cloud-sdk; export CLOUDSDK_CORE_DISABLE_PROMPTS=1; curl https://sdk.cloud.google.com | bash; fi
    source /home/travis/google-cloud-sdk/path.bash.inc # Add gcloud to $PATH
    gcloud version
    gcloud auth activate-service-account --key-file "$FIREBASE_SERVICE_ACCOUNT_FILEPATH"

    # The only way I know to delete existing functions is to deploy empty module:
    cp build/node/index.dart.js build/node/index.dart.js.temp
    cp build/node/clear.dart.js build/node/index.dart.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID"

    firebase functions:config:set --token="$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID" someservice.key=123456 someservice.url="https://example.com" someservice.enabled=true

    # Create new functions
    cp build/node/index.dart.js.temp build/node/index.dart.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN" --project "$FIREBASE_PROJECT_ID"
fi
