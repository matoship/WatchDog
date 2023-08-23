import * as functions from "firebase-functions";
import * as express from "express";
import {addCaregiver, deleteCaregiver, getCaregiver, updateCaregiver}
  from "./clientsController";

const app = express();
app.get("/", (req, res) =>
  res.status(200).send("Hey there!"));

// caregivers profile
app.post("/caregivers", addCaregiver);
app.put("/caregivers/:id", updateCaregiver);
app.get("/caregivers/:id", getCaregiver);
app.delete("/caregivers/:id", deleteCaregiver);

// patient profiles

// app.post("/patients");
// app.put("/patients/:id");
// app.get("/patients/:id");
// app.delete("/patients/:id");

exports.app = functions.https.onRequest(app);
