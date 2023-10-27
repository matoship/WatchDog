import os
from flask import Flask, request, jsonify, send_file
from google.cloud import storage
from face2Numpy import Faces2Numpy
from pathlib import Path


app = Flask(__name__)

bucket_name = "watchdog-gamma.appspot.com"
storage_client = storage.Client()
bucket = storage_client.get_bucket(bucket_name)


@app.route('/update', methods=['GET'])
def process():
    blobs = bucket.list_blobs(prefix="Patients_Images/")
    try:
        for blob in blobs:
            # Create a directory structure similar to the blob's
            destination_folder = os.path.join(
                "/".join(blob.name.split("/")[0:-1]))
            Path(destination_folder).mkdir(parents=True, exist_ok=True)

            # Construct the full local filepath
            destination_file_path = os.path.join(blob.name)

            # Download the blob to the local file
            blob.download_to_filename(destination_file_path)
        Faces2Numpy(Path("Patients_Images"))
        return jsonify({'status': 'Files downloaded successfully'})
    except Exception as e:
        return jsonify({'status': 'Error', 'error': str(e)})


if __name__ == "__main__":
    app.run()
