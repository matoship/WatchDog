from google.cloud import storage
from pathlib import Path
import os


def PreprocessingData(bucket_name: str, patients_videos_prefix: str, patients_images_prefix: str, train_data_prefix: str, test_data_prefix: str):
    """
    Modified function to interact with Google Cloud Storage.
    """
    desired_frame_count = 15
    train_test_split = 0.75
    desired_shape: tuple = (224, 224, 3)
    test_images_extractor: bool = False
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(bucket_name)

    # List all the videos in the specified directory in the bucket
    blobs = bucket.list_blobs(prefix=patients_videos_prefix)

    for blob in blobs:
        file_name = os.path.basename(blob.name)

        if not file_name.endswith((".mp4", ".avi", ".mov")):
            continue

        print(
            f"[INFO] Processing: Patient ID: {os.path.splitext(file_name)[0]}")

        cur_patient_video_path = blob.name
        cur_patient_image_prefix = os.path.join(
            patients_images_prefix, os.path.splitext(file_name)[0])

        # Download the video to temporary storage for processing
        local_video_path = f"/tmp/{file_name}"
        blob.download_to_filename(local_video_path)

        # Apply video to image converter
        Video2ImageConvertor.Video2ImageConvertor(
            local_video_path, cur_patient_image_prefix, desired_frame_count=desired_frame_count)

        # Apply face detection
        FindFacesInImages.FindFacesInImages(cur_patient_image_prefix)

    if not test_images_extractor:
        saved_folder_path = Data2TrainTest.Data2TrainTest(
            patients_images_prefix, train_data_prefix, test_data_prefix, train_ratio=train_test_split)

        # Convert the cropped face images to numpy arrays
        Faces2Numpy.Faces2Numpy(Path(saved_folder_path), Path(
            saved_folder_path), desired_shape)

    print("[INFO] Processing done!")
