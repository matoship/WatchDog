/* eslint-disable require-jsdoc */
/* eslint-disable max-len */
import * as cv from "opencv4nodejs";
import * as fs from "fs";
import * as path from "path";

export function FindFacesInImages(inputFolder: string): void {
  const imagePaths = fs.readdirSync(inputFolder).filter((file) => [".png", ".jpg", ".jpeg"].includes(path.extname(file)));
  const faceCascade = new cv.CascadeClassifier(cv.HAAR_FRONTALFACE_DEFAULT);

  for (const imagePath of imagePaths) {
    const img = cv.imread(path.join(inputFolder, imagePath));
    const gray = img.bgrToGray();
    const faces = faceCascade.detectMultiScale(gray).objects;

    if (faces.length > 0) {
      const [x, y, w, h] = [faces[0].x, faces[0].y, faces[0].width, faces[0].height];
      const faceROI = img.getRegion(new cv.Rect(x, y, w, h));
      cv.imwrite(path.join(inputFolder, imagePath), faceROI);
    } else {
      fs.unlinkSync(path.join(inputFolder, imagePath));
    }
  }

  console.log("[INFO] Face detection and cropping completed.");
}
