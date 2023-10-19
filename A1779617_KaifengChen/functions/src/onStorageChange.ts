// index.ts
import * as functions from "firebase-functions";
// import axios from "axios";

export const onStorageChange = functions.storage
  .bucket("watchdog-gamma.appspot.com")
  .object()
  .onFinalize(async (object) => {
    const filePath = object.name;
    const contentType = object.contentType;

    if (filePath && filePath.startsWith("patients/")) {
      // Check if the file is a video
    //   const parts = filePath.split("/");
      //   const patientIdentifier = parts[1];
      console.log(filePath);
      if (contentType && contentType.startsWith("video/")) {
        // Make an HTTP request to your App Engine application
        // await axios.post("https://your-app-engine-url.com/notify", {
        //   filePath: filePath,
        //   contentType: contentType,
        // });
      } else {
        console.log("Uploaded file is not a video.");
      }
    }
    return null;
  });

