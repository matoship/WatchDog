import cv2
import mediapipe as mp
import sys
import pickle
import face_recognition
import numpy as np
# Firebase setup
import firebase_admin
from firebase_admin import credentials, storage
from firebase_admin import initialize_app
from firebase_functions import https_fn

app = initialize_app()

cred = credentials.Certificate(
    'A1779617_KaifengChen/python-functions/serviceAccount.json')
firebase_admin.initialize_app(cred, {
    'storageBucket': 'watchdog-gamma.appspot.com'
})
bucket = storage.bucket()


class FaceDetector():
    def __init__(self, minDetectionCon=0.5):
        self.minDetectionCon = minDetectionCon
        self.mpFaceDetection = mp.solutions.face_detection
        self.faceDetection = self.mpFaceDetection.FaceDetection(
            self.minDetectionCon)

    def findFaces(self, img, draw=True):
        imgRGB = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        self.results = self.faceDetection.process(imgRGB)
        bboxs = []
        if self.results.detections:
            for id, detection in enumerate(self.results.detections):
                bboxC = detection.location_data.relative_bounding_box
                ih, iw, ic = img.shape
                bbox = int(bboxC.xmin * iw), int(bboxC.ymin *
                                                 ih), int(bboxC.width * iw), int(bboxC.height * ih)
                bboxs.append([id, bbox, detection.score])
        return bboxs


def print_progress_bar(name, iteration, total, bar_length=50):
    progress = (iteration / total)
    arrow = '-' * int(round(progress * bar_length) - 1) + '>'
    spaces = ' ' * (bar_length - len(arrow))
    sys.stdout.write(
        f'\r[INFO] Encoding: {name} {arrow + spaces} {iteration}/{total}')
    sys.stdout.flush()


@https_fn.on_request()
def main(req: https_fn.Request) -> https_fn.Response:
    # Retrieve all file names from Firebase
    dataset_path_from_firebase = 'patient_images'
    blobs = list(bucket.list_blobs(prefix=dataset_path_from_firebase))
    imagePaths = [blob.name for blob in blobs]

    knownEncodings = []
    knownNames = []
    detector = FaceDetector()
    didntFindFaces = 0
    totalImages = len(imagePaths)

    for (i, imagePath) in enumerate(imagePaths):
        name = imagePath.split("/")[-2]

        print_progress_bar(name, i + 1, len(imagePaths))

        # Load the input image from Firebase
        blob = bucket.blob(imagePath)
        img_byte = blob.download_as_bytes()
        img_array = np.frombuffer(img_byte, np.uint8)
        img = cv2.imdecode(img_array, cv2.IMREAD_COLOR)

        bboxs = detector.findFaces(img)

        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        try:
            encodings = face_recognition.face_encodings(rgb, [bboxs[0][1]])
            for encoding in encodings:
                knownEncodings.append(encoding)
                knownNames.append(name)
        except:
            didntFindFaces += 1

    encodings_path_in_firebase = 'encoded_faces/faceEncodings.pickle'
    encoding_data = pickle.dumps(
        {"encodings": knownEncodings, "names": knownNames})
    encoding_blob = bucket.blob(encodings_path_in_firebase)
    encoding_blob.upload_from_string(encoding_data)

    return https_fn.Response(
        f"\n[INFO] Model has an accuracy of: {((totalImages-didntFindFaces)/totalImages)*100}%, found faces in {(totalImages-didntFindFaces)} images, out of {totalImages}.")
