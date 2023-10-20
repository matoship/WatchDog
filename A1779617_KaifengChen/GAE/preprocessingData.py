from google.cloud import storage
from pathlib import Path
import os
import mediapipe as mp
from imutils import paths
import cv2


bucket_name = "watchdog-gamma.appspot.com"
storage_client = storage.Client()


def PreprocessingData(roomNum: str, filePath: str):
    bucket = storage_client.get_bucket(bucket_name)
    desired_frame_count = 15
    blob = bucket.blob(filePath)
    parts = filePath.split("/")
    file_name = parts[2]
    local_video_path = f"/tmp/{file_name}"
    cur_patient_image_prefix = f"/tmp/images"

    blob.download_to_filename(local_video_path)
    # Apply video to image converter
    Video2ImageConvertor(
        local_video_path, cur_patient_image_prefix, desired_frame_count=desired_frame_count)

    # Apply face detection
    FindFacesInImages(cur_patient_image_prefix, roomNum)


def Video2ImageConvertor(video_path: Path, output_folder: Path, desired_frame_count: int):
    """
    Extracts frames from a video and saves them as separate images

    Params:
        video_path: Path to the video file
        output_folder: Path to the folder where the images will be saved
        desired_frame_count: Number of frames to be extracted from the video

    Returns:
        None, but saves the extracted frames to the output folder
    """
    # Ensure the output directory exists
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"[ERROR] Couldn't open the video file {video_path}")
        return

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    skip_interval = total_frames / desired_frame_count

    frame_number = 0
    extracted_count = 0
    while extracted_count < desired_frame_count:
        # Jump to the specified frame number
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_number)
        ret, frame = cap.read()

        if not ret:
            break

        frame_filename = os.path.join(output_folder, f"{extracted_count}.jpg")
        cv2.imwrite(frame_filename, frame)

        frame_number = int(frame_number + skip_interval)
        extracted_count += 1

    cap.release()
    print(
        f"[INFO] Extracted {extracted_count} frames and saved them to {output_folder}")


class FaceDetector():
    def __init__(self, minDetectionCon=0.5):

        self.minDetectionCon = minDetectionCon

        self.mpFaceDetection = mp.solutions.face_detection
        self.faceDetection = self.mpFaceDetection.FaceDetection(
            self.minDetectionCon)

    def findFaces(self, img, draw=True):
        # returns faces - bounding boxes
        imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        self.results = self.faceDetection.process(imgRGB)
        bboxs = []
        if self.results.detections:
            for id, detection in enumerate(self.results.detections):
                bboxC = detection.location_data.relative_bounding_box
                ih, iw, ic = img.shape
                bbox = int(bboxC.xmin * iw), int(bboxC.ymin * ih), \
                    int(bboxC.width * iw), int(bboxC.height * ih)
                bboxs.append([id, bbox, detection.score])
        return bboxs


def FindFacesInImages(input_folder: Path, roomNum: str):
    """
    This function converts Patients full images and detects the faces and saves them in the same folder, under the same name of the image file previously saved.

    Params:ß
    """
    if not os.path.exists(input_folder):
        os.makedirs(input_folder)
    # grab the paths to the input images in our dataset
    imagePaths = list(paths.list_images(input_folder))

    # load the FaceDetector class
    detector = FaceDetector()
    didntFindFaces = 0
    totalImages = len(imagePaths)

    # loop over the image paths
    for (i, imagePath) in enumerate(imagePaths):

        # load the input image and detect faces in it and find bounding boxes
        img = cv2.imread(imagePath)
        bboxs = detector.findFaces(img)
        # print("x:", bboxs[0][0], "1:", bboxs[0][1], "2: ", bboxs[0][2], "y")

        if len(bboxs) != 0:
            try:
                for i in range(len(bboxs)):
                    (startX, startY, w, h) = bboxs[i][1]
                    face = img[startY:startY+h, startX:startX+w]

                    # Save it with the same in imagePath
                    cv2.imwrite(imagePath, face)

                    # Upload face image to Google Cloud Storage
                    upload_blob(bucket_name, imagePath,
                                f'faces/{roomNum}/{Path(imagePath).name}')

            except Exception as e:
                print(f"[ERROR] An error occurred: {e}")
                os.remove(imagePath)
        else:
            didntFindFaces += 1  # "No face found in image"

            # if face is not found, delete the image
            os.remove(imagePath)

    print(
        f"\n[INFO] Model has an accuracy of: {((totalImages-didntFindFaces)/totalImages)*100:.1f}%, found faces in {(totalImages-didntFindFaces)} images, out of {totalImages}.")
    print("[INFO] Found Faces In Images: Processing completed.")


def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    bucket = storage_client.get_bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)

    blob.upload_from_filename(source_file_name)

    print(f"File {source_file_name} uploaded to {destination_blob_name}.")
