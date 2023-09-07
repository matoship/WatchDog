
import * as functions from "firebase-functions";
import {initializeApp} from "firebase-admin/app";
import {credential, firestore} from "firebase-admin";
import {getStorage} from "firebase-admin/storage";


const admin = initializeApp({
  credential: credential.cert({
    privateKey: functions.config().private.key.replace(/\\n/g, "\n"),
    projectId: functions.config().project.id,
    clientEmail: functions.config().client.email,
  }),
  storageBucket: "watchdog-gamma.appspot.com",
});
const bucket = getStorage().bucket();

const db = firestore();
export {admin, db, bucket};
