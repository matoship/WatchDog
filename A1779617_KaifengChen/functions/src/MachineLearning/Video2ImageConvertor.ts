/* eslint-disable require-jsdoc */
/* eslint-disable max-len */
import * as cv from "opencv4nodejs";
import * as fs from "fs";
import * as path from "path";

export function Video2ImageConvertor(videoPath: string, outputFolder: string, desiredFrameCount: number): void {
  if (!fs.existsSync(outputFolder)) {
    fs.mkdirSync(outputFolder, {recursive: true});
  }

  const cap = new cv.VideoCapture(videoPath);
  const totalFrames = cap.get(cv.CAP_PROP_FRAME_COUNT);
  const skipInterval = Math.round(totalFrames / desiredFrameCount);

  let frameNumber = 0;
  let extractedCount = 0;

  while (extractedCount < desiredFrameCount) {
    const frame = cap.read();

    if (frame.empty) break;

    const frameFilename = path.join(outputFolder, `${extractedCount}.jpg`);
    cv.imwrite(frameFilename, frame);

    frameNumber += skipInterval;
    cap.set(cv.CAP_PROP_POS_FRAMES, frameNumber);
    extractedCount++;
  }

  console.log(`[INFO] Extracted ${extractedCount} frames and saved them to ${outputFolder}`);
}
