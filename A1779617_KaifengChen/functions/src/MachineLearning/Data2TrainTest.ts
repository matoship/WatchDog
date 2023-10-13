/* eslint-disable require-jsdoc */
/* eslint-disable max-len */
import * as fs from "fs";
import * as path from "path";

export function Data2TrainTest(sourceDir: string, trainTargetDir: string, testTargetDir: string, trainRatio: number): void {
  const FOLDER_NAME = "data";
  trainTargetDir = path.join(FOLDER_NAME, trainTargetDir);
  testTargetDir = path.join(FOLDER_NAME, testTargetDir);

  if (!fs.existsSync(trainTargetDir)) {
    fs.mkdirSync(trainTargetDir, {recursive: true});
  }

  if (!fs.existsSync(testTargetDir)) {
    fs.mkdirSync(testTargetDir, {recursive: true});
  }

  const persons = fs.readdirSync(sourceDir).filter((dir) => fs.lstatSync(path.join(sourceDir, dir)).isDirectory());

  for (const person of persons) {
    const images = fs.readdirSync(path.join(sourceDir, person)).filter((file) => [".png", ".jpg", ".jpeg"].includes(path.extname(file)));
    const splitIdx = Math.floor(trainRatio * images.length);
    const trainImages = images.slice(0, splitIdx);
    const testImages = images.slice(splitIdx);

    const trainPersonDir = path.join(trainTargetDir, person);
    const testPersonDir = path.join(testTargetDir, person);

    if (!fs.existsSync(trainPersonDir)) {
      fs.mkdirSync(trainPersonDir);
    }

    if (!fs.existsSync(testPersonDir)) {
      fs.mkdirSync(testPersonDir);
    }

    trainImages.forEach((img, idx) => {
      const newImgName = `${idx}${path.extname(img)}`;
      fs.renameSync(path.join(sourceDir, person, img), path.join(trainPersonDir, newImgName));
    });

    testImages.forEach((img, idx) => {
      const newImgName = `${idx}${path.extname(img)}`;
      fs.renameSync(path.join(sourceDir, person, img), path.join(testPersonDir, newImgName));
    });
  }

  console.log("[INFO] Data split into training and testing sets.");
}
