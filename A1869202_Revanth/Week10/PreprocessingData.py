from pathlib import Path
import FindFacesInImages
import Video2ImageConvertor
import Data2TrainTest
import argparse
import os
import sys
import shutil

def PreprocessingData(patients_videos_path:Path, patients_images_path:Path, desired_frame_count:int, train_data_path:Path, test_data_path:Path, train_test_split:Path):
    """
    This function takes the path to the patients videos and images folder and applies the following steps:
        1. Converts the videos to images
        2. Detects faces in the images
        3. Splits the data into train and test folders
    """
    for patient in os.listdir(patients_videos_path):
        # only pass video files like - .mp4, .avi, .mov
        if not patient.endswith(".mp4") and not patient.endswith(".avi") and not patient.endswith(".mov"):
            continue

        # Only print the patient name, not the extension            
        print("[INFO] Processing: Patient ID: ", os.path.splitext(patient)[0])
        cur_patient_video_path = os.path.join(patients_videos_path, patient)
        cur_patient_image_path = os.path.join(patients_images_path, os.path.splitext(patient)[0])
        
        # Apply video to image convertor
        Video2ImageConvertor.Video2ImageConvertor(cur_patient_video_path, cur_patient_image_path, desired_frame_count=desired_frame_count)

        # Apply face detection
        FindFacesInImages.FindFacesInImages(cur_patient_image_path)
        
    # Apply data to train and test split
    Data2TrainTest.Data2TrainTest(patients_images_path, train_data_path, test_data_path, train_ratio=train_test_split)

    # Delete the patients_images_path folder
    shutil.rmtree(patients_images_path)

    print("[INFO] Processing done!")

if __name__ == "__main__":
    # construct the argument parser and parse the arguments
    ap = argparse.ArgumentParser()
    ap.add_argument("-v", "--patients_videos_path", required=True,
        help="path to recorded patients videos folder")
    ap.add_argument("-i", "--patients_images_path", required=True,
        help="path to create patients images folder")
    ap.add_argument("-fc", "--desired_frame_count", required=True,
        help="How many images to be converted from the given video/desired frame count")
    ap.add_argument("-tr", "--train_data_path", required=True, 
        help="path to create train data folder, saved under 'data/train_data_path' folder")
    ap.add_argument("-te", "--test_data_path", required=True,
        help="path to create test data folder, saved under 'data/test_data_path' folder")
    ap.add_argument("-r", "--train_ratio", required=True,
                    help="train-test split ratio, suggested split is 0.7, means 70% train and 30% test data")
    args = vars(ap.parse_args())

    # Check if the given patients_videos_path exists
    if not os.path.exists(args["patients_videos_path"]):
        print(f"[ERROR] The given patients_videos_path {args['patients_videos_path']} doesn't exist!")
        sys.exit()

    # Extract the arguments from the args dictionary and pass them to the function
    PreprocessingData(Path(args["patients_videos_path"]), Path(args["patients_images_path"]), int(args["desired_frame_count"]), Path(args["train_data_path"]), Path(args["test_data_path"]), float(args["train_ratio"]))

    # Run the script like this:
    # python PreprocessingData.py -v Patients_Videos -i Patients_Images -fc 72 -tr "train" -te "test" -r 0.7 