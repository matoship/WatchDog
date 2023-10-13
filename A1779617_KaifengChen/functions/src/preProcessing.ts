/* eslint-disable max-len */
/* eslint-disable require-jsdoc */
import * as fs from "fs";
import * as path from "path";
import {Video2ImageConvertor} from "./Video2ImageConvertor";
import {FindFacesInImages} from "./FindFacesInImages";
import {Data2TrainTest} from "./Data2TrainTest";

function PreprocessingData(
  patientsVideosPath: string,
  patientsImagesPath: string,
  desiredFrameCount: number,
  trainDataPath: string,
  testDataPath: string,
  trainTestSplit: number
): void {
  const videoFiles = fs.readdirSync(patientsVideosPath);

  for (const patient of videoFiles) {
    if (!patient.endsWith(".mp4") && !patient.endsWith(".avi") && !patient.endsWith(".mov")) {
      continue;
    }

    console.log(`[INFO] Processing: Patient ID: ${path.basename(patient, path.extname(patient))}`);
    const curPatientVideoPath = path.join(patientsVideosPath, patient);
    const curPatientImagePath = path.join(patientsImagesPath, path.basename(patient, path.extname(patient)));

    Video2ImageConvertor(curPatientVideoPath, curPatientImagePath, desiredFrameCount);
    FindFacesInImages(curPatientImagePath);
  }

  Data2TrainTest(patientsImagesPath, trainDataPath, testDataPath, trainTestSplit);
  fs.rmSync(patientsImagesPath, {recursive: true, force: true});
  console.log("[INFO] Processing done!");
}
