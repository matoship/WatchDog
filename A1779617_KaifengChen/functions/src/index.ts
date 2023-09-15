/* eslint-disable max-len */
import * as functions from "firebase-functions";
import * as express from "express";
import Routes from "./routes";
import {realtimeDb, db, messaging} from "./config/firebase";

const watchdogGamma = express();

watchdogGamma.use(Routes);

exports.app = functions.region("australia-southeast1").
  https.onRequest(watchdogGamma);


export const writeData = functions.https.onRequest(async (req, res) => {
  const {id} = req.query;
  console.log(id);
  const newItem = {
    "bedExitted?": true,
    "fallDetected?": false,
  };
  const newItemRef = realtimeDb.ref(`/BedExits_and_FallDetections/${id}`);
  // Set the new item's data
  await newItemRef.set(newItem);

  res.status(200).send(`New item added with ID: ${newItemRef.key}`);
});

export const updateData = functions.https.onRequest(async (req, res) => {
  const {id} = req.query;
  console.log(`Updating ID: ${id}`);

  // Define the data you want to update
  const updatedData = {
    "bedExitted?": false, // Update as needed
    "fallDetected?": true, // Update as needed
  };

  // Reference to the specific database node you want to update
  const itemRef = realtimeDb.ref(`/BedExits_and_FallDetections/${id}`);

  // Update the data at the specified reference
  await itemRef.update(updatedData);

  res.status(200).send(`Item with ID ${id} has been updated.`);
});


  interface DataType {
    bedExitted: boolean;
    fallDetected: boolean; // Corrected typo here
  }

export const onDatabaseChange = functions.database
  .instance("falldetection-and-bedexits")
  .ref("/BedExits_and_FallDetections/{roomid}")
  .onWrite(async (change, context) => {
    const roomId = context.params.roomid;
    const beforeData = change.before.val() as DataType || {};
    const afterData = change.after.val() as DataType || {};
    let patientInfo;
    let ruleViolated = false;
    // Query Firestore for patients with the same roomid
    const patientQuery = await db.collection("patients").where("roomNum", "==", roomId).get();
    if (!patientQuery.empty) {
      const patientDoc = patientQuery.docs[0];
      patientInfo = patientDoc.data();
      console.log(`Found patient with matching room ID: ${JSON.stringify(patientInfo)}`);
    } else {
      console.log(`No patient found with room ID: ${roomId}`);
      return null;
    }

    const {allowedInBed, careGiverId} = patientInfo;
    const {bedExitted, fallDetected} = afterData;
    if (allowedInBed==true && bedExitted==true) {
      ruleViolated = true;
    }

    const changes: {[key: string]: {oldValue: boolean, newValue: boolean}} = {};
    for (const [key, value] of Object.entries(afterData)) {
      if (beforeData[key as keyof DataType] !== value) {
        changes[key] = {
          oldValue: beforeData[key as keyof DataType],
          newValue: value,
        };
      }
    }
    if (fallDetected==true || ruleViolated == true) {
      // Create the payload for the FCM message.
      // You can also use the 'notification' field for standard notifications.
      console.log("sending the message");
      const payload = {
        data: {
          title: `Data changed for patient ${patientInfo.id}`,
          body: `The following fields have changed: ${JSON.stringify(changes)}`,
          patientInfo: JSON.stringify(patientInfo),
        },
      };
      // Publish the message to a topic.
      // The topic name is constructed using the roomId.
      return messaging.sendToTopic(`careGiverId-${careGiverId}`, payload)
        .then((response) => {
          // Log the successful FCM response
          console.log(`Successfully sent FCM message to topic careGiverId-${careGiverId}: `, response);
          return null;
        })
        .catch((error) => {
          // Log the error and proceed
          console.log(`Error sending FCM message to topic careGiverId-${careGiverId}: `, error);
          return null;
        });
    }

    return null;
  });
