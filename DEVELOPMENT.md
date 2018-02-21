# Development

Requirements:

* Dart SDK 2
* NodeJS
* Firebase Tools (`npm install -g firebase-tools`)

## Running tests

To run the tests locally you'll need to create Firebase Service Account
used by Firebase Admin SDK. Instructions can be found here:
https://firebase.google.com/docs/admin/setup

Download service account key file somewhere **outside** of this Git
repository (so that there is no chance to accidentally commit it) and
set following environment variable to the file's absolute path:

```bash
export FIREBASE_SERVICE_ACCOUNT_FILEPATH="/Users/me/full-path-to-service-account-key.json"
```

Set a couple more environment variables:

```
export FIREBASE_DATABASE_URL="https://your-project-id.firebaseio.com"
export FIREBASE_HTTP_BASE_URL="https://us-central-your-project-id.cloudfunctions.net"
```

The test suite depends on predefined test functions which must be
(re)deployed before running the tests:

```bash
./tool/deploy.sh
```

Running the tests:

```bash
pub run test
```
