from pathlib import Path
import FindFacesInImages
import Video2ImageConvertor
import Data2TrainTest
import Faces2Numpy
import os
from flask import Flask, request, jsonify
from google.cloud import storage

app = Flask(__name__)
storage_client = storage.Client()


def upload_blob(bucket_name, source_file_name, destination_blob_name):
    """Uploads a file to the bucket."""
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(destination_blob_name)
    blob.upload_from_filename(source_file_name)
    print(f"File {source_file_name} uploaded to {destination_blob_name}.")


def download_blob(bucket_name, source_blob_name, destination_file_name):
    """Downloads a blob from the bucket."""
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(source_blob_name)
    blob.download_to_filename(destination_file_name)
    print(f"Blob {source_blob_name} downloaded to {destination_file_name}.")


@app.route('/process', methods=['POST'])
def process_data():
    data = request.json
    patients_videos_path_gcs = data['name']

    # Convert GCS paths to bucket and blob
    bucket_name = 'watchdog-gamma.appspot.com'  # Your bucket name
    local_path = '/tmp/patient_video.mp4'  # Temporary storage in Cloud Run instance

    # Download the changed file from GCS to the local filesystem
    download_blob(bucket_name, patients_videos_path_gcs, local_path)

    # Extract other parameters
    patients_images_path = '/tmp/patients_images'  # Temporary local storage
    train_data_path = data['train_data_path']
    test_data_path = data['test_data_path']
    train_test_split = float(data['train_test_split'])
    desired_shape_value = 224
    desired_shape = (desired_shape_value, desired_shape_value, 3)
    test_images_extractor = False

    # Call your processing function
    PreprocessingData(
        Path(local_path),
        Path(patients_images_path),
        72,
        Path(train_data_path),
        Path(test_data_path),
        train_test_split,
        desired_shape,
        test_images_extractor
    )

    # Upload processed data back to GCS
    # Assuming 'patients_images' folder has the processed data you want to upload
    for root, _, files in os.walk(patients_images_path):
        for file in files:
            local_file = os.path.join(root, file)
            blob_name = os.path.relpath(local_file, patients_images_path)
            upload_blob(bucket_name, local_file,
                        f"patients_images/{blob_name}")

    return jsonify({"message": "Processing done!"})


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)
