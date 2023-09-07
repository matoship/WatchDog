import * as functions from "firebase-functions";
import * as express from "express";
import Routes from "./routes";

const app = express();

app.use(Routes);

exports.app = functions.https.onRequest(app);
