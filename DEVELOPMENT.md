# Development

Requirements:

* Dart SDK 2
* Node.js
* Firebase Tools (`npm install -g firebase-tools` or `yarn global add firebase-tools`)
* GCloud SDK (https://cloud.google.com/sdk/docs/quickstart-macos for MacOS)

## Running tests

To run the tests locally you'll need to:

* [Create a Firebase project](https://console.firebase.google.com/) for testing
    * Use `firebase use --add` to add it to this project

* Download [Service Account file](https://console.firebase.google.com/project/_/settings/serviceaccounts/adminsdk) (and database URL)
    * Download the service account key file somewhere **outside** of this Git
      repository (so that there is no chance to accidentally commit it)

* Set the environment variables:
    * Use the absolute path of the service account file, with the database URL you found above:
    * ```bash
      export FIREBASE_SERVICE_ACCOUNT_JSON='<json_content_from_your_service_account_file_in_single_line>'
      export FIREBASE_CONFIG='{"databaseURL": "https://<project-id>.firebaseio.com","projectId": "<project-id>"}'
      export FIREBASE_HTTP_BASE_URL="https://us-central1-<project-id>.cloudfunctions.net"
      ```

* You need to:
    * activate the firestore database (Firebase Console)
    * create a pubsub topic with `gcloud beta pubsub topics create testTopic`

* Deploy the test suite:
    * ```bash
      sh tool/deploy.sh
      ```

* Run the tests:
    * ```bash
      pub run test
      ```
