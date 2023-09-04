import * as functions from "firebase-functions";
import * as express from "express";
import caregiversRoutes from "./routes";
import * as admin from "firebase-admin";

const app = express();

app.use(caregiversRoutes);


/**
 * Initialize the Firebase Admin SDK.
 *
 * Make sure to replace './path/to/your-service-account-file.json' with the
 * path to your service account JSON file downloaded from Firebase console.
 */

/**
 * Asynchronously send a notification message to a specific device.
 *
 * @param {string} deviceToken - The FCM device token of the target device.
 * @param {string} title - The title of the notification.
 * @param {string} body - The body content of the notification.
 * @return {Promise<void>} - A promise that resolves when the message is sent.
 */
async function sendMessage(deviceToken: string, title: string, body: string):
    Promise<void> {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: deviceToken,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
  } catch (error) {
    console.log("Error sending message:", error);
  }
}

// Usage
const deviceToken = "YOUR_DEVICE_TOKEN_HERE";
const title = "Notification Title";
const body = "Notification Body";

sendMessage(deviceToken, title, body);

// patient profiles

// app.post("/patients");
// app.put("/patients/:id");
// app.get("/patients/:id");
// app.delete("/patients/:id");

exports.app = functions.https.onRequest(app);
