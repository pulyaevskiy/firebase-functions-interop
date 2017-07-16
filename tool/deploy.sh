#!/bin/bash

set -e

cd functions
pub build bin

# The only way I know to delete existing functions is to deploy empty module:
cp build/bin/clear.dart.js index.js
firebase deploy --only functions --token "$FIREBASE_TOKEN"

# Create new functions
cp build/bin/index.dart.js index.js
firebase deploy --only functions --token "$FIREBASE_TOKEN"
