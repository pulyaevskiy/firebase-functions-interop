#!/bin/bash

set -e

pub get

cd functions
pub get
npm install
pub build bin

if [ -z "$TRAVIS" ]; then
    echo "Provisioning functions for dev environment"
    # The only way I know to delete existing functions is to deploy empty module:
    cp build/bin/clear.dart.js index.js
    firebase deploy --only functions

    # Create new functions
    cp build/bin/index.dart.js index.js
    firebase deploy --only functions
else
    echo "Provisioning functions for Travis build environment"
    echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$FIREBASE_SERVICE_ACCOUNT_FILEPATH"
    # The only way I know to delete existing functions is to deploy empty module:
    cp build/bin/clear.dart.js index.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN"

    # Create new functions
    cp build/bin/index.dart.js index.js
    firebase deploy --only functions --token "$FIREBASE_TOKEN"
fi
