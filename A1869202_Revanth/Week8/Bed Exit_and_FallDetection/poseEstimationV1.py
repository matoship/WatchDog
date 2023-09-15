import argparse
import time
import cv2
import sys
import enum
from ml import Movenet
from ml import MoveNetMultiPose
from typing import List, Tuple
from data import Person
import numpy as np

# Bed Detection
from tflite_support.task import core
from tflite_support.task import processor
from tflite_support.task import vision
import utils

# Realtime storage Firebase
import pyrebase

# PREVIOUS VALUES
BED_EXITTED = False
FALL_DETECTED = False

def calculate_CoG(total_x, total_y, num_points):
    return (total_x // num_points, total_y // num_points) if num_points else (0, 0)

def visualize(image: np.ndarray, list_persons: List[Person], bed_start_point_x: int, bed_end_point_x: int, database, roomNo: int, BedStartPoint, BedEndPoint, keypoint_threshold: float = 0.12, instance_threshold: float = 0.1) -> np.ndarray:
    global BED_EXITTED
    global FALL_DETECTED

    # Setting Fall threshold = 60% of height of frame
    fall_threshold = image.shape[0] * 0.68
    
    # Divide keypoints into upper, lower, and whole body
    upper_body_parts = ["NOSE", "LEFT_EYE", "RIGHT_EYE", "LEFT_EAR", "RIGHT_EAR", "LEFT_SHOULDER", "RIGHT_SHOULDER","LEFT_ELBOW", "RIGHT_ELBOW", "LEFT_WRIST", "RIGHT_WRIST"]
    lower_body_parts = ["LEFT_HIP", "RIGHT_HIP", "LEFT_KNEE", "RIGHT_KNEE", "LEFT_ANKLE", "RIGHT_ANKLE"]

    # Draw bed
    cv2.rectangle(image, BedStartPoint, BedEndPoint, (255, 0, 0), 3)
    
    for person in list_persons:
        if person.score < instance_threshold:
            continue

        keypoints = person.keypoints
        bounding_box = person.bounding_box
        
        # Calculate COG_Y for whole, upper, lower body
        total_x_whole, total_y_whole, count_whole = 0, 0, 0
        total_x_upper, total_y_upper, count_upper = 0, 0, 0
        total_x_lower, total_y_lower, count_lower = 0, 0, 0

        for i in range(len(keypoints)):
            if keypoints[i].score >= keypoint_threshold:
                # COG_Y for whole body
                total_x_whole += keypoints[i].coordinate.x
                total_y_whole += keypoints[i].coordinate.y
                count_whole += 1

                if keypoints[i].body_part.name in upper_body_parts:
                    # COG_Y for upper body
                    total_x_upper += keypoints[i].coordinate.x
                    total_y_upper += keypoints[i].coordinate.y
                    count_upper += 1
                elif keypoints[i].body_part.name in lower_body_parts:
                    # COG_Y for lower body
                    total_x_lower += keypoints[i].coordinate.x
                    total_y_lower += keypoints[i].coordinate.y
                    count_lower += 1
        
        # Calculate COG_Y for whole, upper, lower body
        COGWhole_x, COGWhole_y = calculate_CoG(total_x_whole, total_y_whole, count_whole)
        COGUpper_x, COGUpper_y = calculate_CoG(total_x_upper, total_y_upper, count_upper)
        COGLower_x, COGLower_y = calculate_CoG(total_x_lower, total_y_lower, count_lower)

        # Draw COG points on image differnt color and bigger size
        cv2.circle(image, (COGWhole_x, COGWhole_y), 10, (0, 0, 255), -1)
        cv2.circle(image, (COGUpper_x, COGUpper_y), 10, (0, 255, 0), -1)
        cv2.circle(image, (COGLower_x, COGLower_y), 10, (255, 0, 0), -1)

        if bounding_box is not None:
            start_point = bounding_box.start_point
            end_point = bounding_box.end_point
            cv2.rectangle(image, start_point, end_point, (0, 255, 0), 2)  # Green color for bounding box

            # For a Fall to be detected: 2 conditions must be met:
            # 1. The COG_Y Coordinate of the whole, upper, lower must be lower than half of height of frame
            # 2. The height - width of bounding box must be lesser than 0.

            difference_height_width = (end_point.y - start_point.y) - (end_point.x - start_point.x)
            if (COGWhole_x < bed_start_point_x or COGWhole_x > bed_end_point_x):
                if (COGWhole_y > fall_threshold) and (COGUpper_y > fall_threshold) and (COGLower_y > fall_threshold) and (difference_height_width < 0):
                    cv2.putText(image, "FALL DETECTED", (start_point.x, start_point.y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 2)

                    if (not FALL_DETECTED):
                        database.child("BedExits_and_FallDetections").child(roomNo).set({"bedExitted?":True, "fallDetected?":True})
                        BED_EXITTED = True
                        FALL_DETECTED = True
                else:
                    if (not BED_EXITTED):
                        database.child("BedExits_and_FallDetections").child(roomNo).set({"bedExitted?":True, "fallDetected?":False})
                        BED_EXITTED = True
                        FALL_DETECTED = False
                cv2.putText(image, "BED EXITTED?: TRUE", (BedStartPoint[0], BedStartPoint[1] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 2)
            else:
                if (BED_EXITTED):
                    database.child("BedExits_and_FallDetections").child(roomNo).set({"bedExitted?":False, "fallDetected?":False})
                    BED_EXITTED = False
                    FALL_DETECTED = False
                cv2.putText(image, "BED EXITTED?: FALSE", (BedStartPoint[0], BedStartPoint[1] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 240, 240), 2)

    return image

def preprocess_image(image):
    return cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

def getBedCoordinates(camera_id: int, frameWidth: int, frameHeight: int, frame_threshold: int, model_path = "bed.tflite", num_threads = 4):
    BedStartPoint_avg, BedEndPoint_avg = (0.0, 0.0), (frameHeight, frameWidth)

    # Constants
    COLORS = [(0, 0, 255)]  # Red for visualization
    FONT_SIZE = 1
    FONT_THICKNESS = 1
    LEFT_MARGIN = 24
    ROW_SIZE = 20

    # Initialize the webcam
    cap = cv2.VideoCapture(camera_id)
    if not cap.isOpened():
        sys.exit('ERROR: Unable to initialize webcam.')
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, frameWidth)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, frameHeight)

    # Load the TFLite model
    options = vision.ObjectDetectorOptions(
        base_options=core.BaseOptions(file_name=model_path, num_threads=num_threads),
        detection_options=processor.DetectionOptions(max_results=1, score_threshold=0.3)
    )
    detector = vision.ObjectDetector.create_from_options(options)

    start_time = time.time()
    frame_count = 0
    
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame_count += 1
        frame = cv2.flip(frame, 1)
        rgb_image = preprocess_image(frame)
        tensor_image = vision.TensorImage.create_from_array(rgb_image)
        detection_result = detector.detect(tensor_image)
        frame, bed_start_point, bed_end_point = utils.visualize(frame, detection_result)
        
        try:
            BedStartPoint_avg = (max(BedStartPoint_avg[0], bed_start_point[0]), max(BedStartPoint_avg[1], bed_start_point[1]))
            BedEndPoint_avg = (min(BedEndPoint_avg[0], bed_end_point[0]), min(BedEndPoint_avg[1], bed_end_point[1]))
        except Exception as e:
            print(f"An error occurred: {e}")
        
        # Calculate and display FPS
        elapsed_time = time.time() - start_time
        fps = frame_count / elapsed_time
        fps_text = f"FPS: {fps:.2f}"
        cv2.putText(frame, fps_text, (LEFT_MARGIN, ROW_SIZE), cv2.FONT_HERSHEY_PLAIN, FONT_SIZE, COLORS[0], FONT_THICKNESS)
        cv2.imshow('Bed Detection', frame)

        # Exit on pressing 'ESC'
        if cv2.waitKey(1) == 27  or frame_count>=frame_threshold: # Run for defined threshold
            break

    cap.release()
    cv2.destroyAllWindows()
    
    # Return the outputs        
    return BedStartPoint_avg, BedEndPoint_avg
    
def run(estimation_model: str, camera_id: int, width: int, height: int, roomNo: int, frame_threshold: int, database) -> None:
    """Continuously run inference on images acquired from the camera."""

    # Initialize the pose estimator selected.
    if estimation_model in ['movenet_lightning', 'movenet_thunder']:
        pose_detector = Movenet(estimation_model)
    elif estimation_model == 'movenet_multipose':
        pose_detector = MoveNetMultiPose(estimation_model)
    else:
        sys.exit('ERROR: Model is not supported.')

    print("INFO: Initiating bed detection within the patient's room...")
    BedStartPoint, BedEndPoint = getBedCoordinates(camera_id, width, height, frame_threshold)
    time.sleep(0.2)
    print("INFO: Bed detected. Now initiating fall detection inside the room...")

    # Start capturing video input from the camera
    cap = cv2.VideoCapture(camera_id)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, height)
    time.sleep(0.2)

    # Variables to calculate FPS
    counter, fps = 0, 0
    fps_avg_frame_count = 10
    start_time = time.time()

    while cap.isOpened():
        success, image = cap.read()
        if not success:
            sys.exit('ERROR: Unable to read from webcam. Please verify your webcam settings.')
        
        counter += 1
        image = cv2.flip(image, 1)

        if estimation_model == 'movenet_multipose':
            list_persons = pose_detector.detect(image)
        else:
            list_persons = [pose_detector.detect(image)]

        # Draw keypoints on input image
        image = visualize(image, list_persons, BedStartPoint[0], BedEndPoint[0], database, roomNo, BedStartPoint, BedEndPoint)

        # Calculate and display FPS
        if counter % fps_avg_frame_count == 0:
            end_time = time.time()
            fps = fps_avg_frame_count / (end_time - start_time)
            start_time = time.time()

        fps_text = 'FPS = ' + str(int(fps))
        cv2.putText(image, fps_text, (10, 30), cv2.FONT_HERSHEY_PLAIN, 1, (0, 0, 255), 1)
        
        cv2.imshow(estimation_model, image)
        if cv2.waitKey(1) == 27:  # ESC key
            break

    cap.release()
    cv2.destroyAllWindows()


def main():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--model', help='Name of estimation model.', default='movenet_lightning', type=str)
    parser.add_argument('--cameraId', help='Id of camera.', default=0, type=int)
    parser.add_argument('--frameWidth', help='Width of frame to capture from camera.', default=640, type=int)
    parser.add_argument('--frameHeight', help='Height of frame to capture from camera.', default=480, type=int)
    parser.add_argument('--roomNo', help='This device installed room number in hospital/home.', default=1, type=int)
    parser.add_argument('--frameThreshold', help='No of frames average to calculate bed dimensions.', default=20, type=int)
    args = parser.parse_args()

    config = {
        "apiKey": "AIzaSyBMd8nI8zniWNtQ5RvVRitmpgUpV1ucUYk",
        "authDomain": "watchdog-gamma.firebaseapp.com",
        "databaseURL": "https://falldetection-and-bedexits.firebaseio.com",
        "projectId": "watchdog-gamma",
        "storageBucket": "watchdog-gamma.appspot.com",
        "messagingSenderId": "503315913339",
        "appId": "1:503315913339:web:7a0951b5c54c424c7420de",
        "measurementId": "G-P99HVG61KT"
    }
    firebase = pyrebase.initialize_app(config)
    database = firebase.database()
    data = { # Set the default values for 'bedExitted?' and 'fallDetected?'
        "bedExitted?": False,  # or True, depending on the situation
        "fallDetected?": False  # or True, depending on the situation
    }
    database.child("BedExits_and_FallDetections").child(args.roomNo).set(data)

    run(args.model, args.cameraId, args.frameWidth, args.frameHeight, args.roomNo, args.frameThreshold, database)

if __name__ == '__main__':
    main()
