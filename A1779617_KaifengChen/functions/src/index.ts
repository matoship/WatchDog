/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onRequest} from "firebase-functions/v2/https";
import * as functions from "firebase-functions";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
const databaseURL ="127.0.0.1:9000";
admin.initializeApp({
  databaseURL: databaseURL,
});

export const helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

export const saveData = functions.https.onRequest((req, res) => {
  if (req.method !== "POST") {
    res.status(400).send("Please send a POST request");
    return;
  }

  const data = req.body; // Assuming the JSON data is in the request body

  admin.database().ref("/user").push(data)
    .then((snapshot) => {
      res.status(200).send(snapshot.key);
    })
    .catch((error) => {
      console.error(error);
      res.status(500).send("An error occurred while saving data");
    });
});
