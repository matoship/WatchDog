import tensorflow as tf
from tensorflow import keras
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint
import os
import pandas as pd
import matplotlib.pyplot as plt
from tqdm.auto import tqdm
from pathlib import Path
import argparse
from timeit import default_timer as timer

def data_generator(data_dir: Path, mode:str, batch_size:int = 40):
    """
    This function creates data generators for the given data directory.

    Params:
        data_dir: Path to the data directory
        mode: Mode of the program, train or test
        batch_size: Batch size for the data generators
    
    Returns:
        image_data_gen: Image data generator, A dictionary of train and test data generators.
        It Can be accessed as image_data_gen['train'] and image_data_gen['test']
    """
    INPUT_SHAPE = (224, 224) # (300, 300) for MobileNetV2, others (224, 224)

    if mode == "train":
        # Define the data transformations using ImageDataGenerator
        data_generators = {
            'train': ImageDataGenerator(
                rescale=1./255,  # Rescaling
                rotation_range=20,  # Random rotations for data augmentation
                width_shift_range=0.2,  # Random width shift for data augmentation
                height_shift_range=0.2,  # Random height shift for data augmentation
                horizontal_flip=True  # Random horizontal flips for data augmentation
            ),
            'test': ImageDataGenerator(
                rescale=1./255  # Only rescaling for testing data
            )
        }

        # Create data generators from directory
        image_data_gen = {
            'train': data_generators['train'].flow_from_directory(
                os.path.join(data_dir, 'train'),
                target_size=INPUT_SHAPE, #(300, 300), # (224, 224) for MobileNetV2
                batch_size=batch_size,
                shuffle=True,
                class_mode='categorical'  # Changed to 'categorical' for multi-class
            ),
            'test': data_generators['test'].flow_from_directory(
                os.path.join(data_dir, 'test'),
                target_size=INPUT_SHAPE,
                batch_size=batch_size,
                shuffle=True,
                class_mode='categorical'  # Changed to 'categorical' for multi-class
            )
        }

        class_names = list(image_data_gen['train'].class_indices.keys())
        print(f"[INFO] There are {len(class_names)} classes.")

        return image_data_gen
    
    else:
        # Define the data transformations using ImageDataGenerator
        data_generators = {
            'test': ImageDataGenerator(
                rescale=1./255  # Only rescaling for testing data
            )
        }

        # Create data generators from directory
        image_data_gen = {
            'test': data_generators['test'].flow_from_directory(
                os.path.join(data_dir, 'test'),
                target_size=INPUT_SHAPE,
                batch_size=batch_size,
                shuffle=True,
                class_mode='categorical'  # Changed to 'categorical' for multi-class
            )
        }

        class_names = list(image_data_gen['test'].class_indices.keys())
        print(f"[INFO] There are {len(class_names)} classes.")

        return image_data_gen

def model(model_name:str, out_features: int, input_shape:tuple = (300, 300, 3)): # (224, 224) for MobileNetV2, others (300, 300)
    """
    This function creates a model based on the given model name.

    Params:
        model_name: Name of the model to be created
        out_features: Number of output features
        input_shape: Input shape of the model
    
    Returns:
        model: The created model

    Available models:
        > VGG19, VGG16_A, VGG16_B, INCEPTIONV3, MOBILENETV2, RESNET101V2 
    """

    model = keras.models.Sequential()

    if model_name == "VGG19":
        # VGG19

        model.add(tf.keras.applications.VGG19(
            include_top=False,
            weights="imagenet",
            input_shape=input_shape))

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set TL layers not trainable
        model.layers[0].trainable = False
    
    elif model_name == "VGG16_A":
        # VGG16
        model.add(tf.keras.applications.VGG16(
            include_top=False,
            weights="imagenet",
            input_shape=input_shape))

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set TL layers not trainable
        model.layers[0].trainable = False
    
    elif model_name == "VGG16_B":
        # VGG16
        model.add(tf.keras.applications.VGG16(
            include_top=False,
            weights="imagenet",
            input_shape=input_shape))

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set TL layers not trainable
        model.layers[0].trainable = False

    elif model_name == "INCEPTIONV3":
        # INCEPTION V3

        model.add(tf.keras.applications.InceptionV3(
            include_top=False,
            weights="imagenet",
            input_shape=input_shape))

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set TL layers not trainable
        model.layers[0].trainable = False
    
    elif model_name == "MOBILENETV2":
        
        model.add(tf.keras.applications.MobileNetV2(
            include_top=False,
            weights="imagenet",
            input_shape=(224, 224, 3))) # Only for this network

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set TL layers not trainable
        model.layers[0].trainable = False
    
    elif model_name == "RESNET101V2":
        
        model.add(tf.keras.applications.ResNet101V2(
            include_top=False,
            weights="imagenet",
            input_shape=input_shape))

        # Other layers
        model.add(keras.layers.Flatten())
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(1024, activation='relu'))
        model.add(keras.layers.Dense(512, activation='relu'))
        model.add(keras.layers.Dense(256, activation='relu'))
        model.add(keras.layers.Dropout(0.2))
        model.add(keras.layers.Dense(out_features, activation='softmax'))

        # Set EfficientNet layers not trainable
        model.layers[0].trainable = False
    
    else:
        print("[ERROR] Invalid model name!")

    return model

def train(model, image_data_gen, model_name:str, epochs:int = 10, patience:int = 5, learning_rate:float = 0.001):
    """
    This function trains the given model.

    Params:
        model: Model to be trained
        image_data_gen: Image data generator
        model_name: Name of the model
        epochs: Number of epochs
        patience: Patience for early stopping
    
    Returns:
        history: Training history
    """

    # Compile the model
    model.compile(optimizer=tf.keras.optimizers.legacy.Adam(learning_rate=learning_rate), loss='categorical_crossentropy', metrics=['accuracy'])

    # EarlyStopping callback
    early_stopping_cb = keras.callbacks.EarlyStopping(monitor='accuracy', patience=patience, restore_best_weights=True)

    # ModelCheckpoint callback
    model_name = model_name + ".h5"
    model_checkpoint_cb = keras.callbacks.ModelCheckpoint(model_name, monitor='accuracy', save_best_only=True)

    # Combining all callbacks into a list
    callbacks = [early_stopping_cb, model_checkpoint_cb]

    # Training
    history = model.fit(image_data_gen['train'], epochs=epochs, callbacks=callbacks)

    print("[INFO] Training done!")
    return history

def test(model, image_data_gen):
    """
    This function tests the given model.

    Params:
        model: Model to be tested
        image_data_gen: Image data generator
    
    Returns:
        history: Testing history
    """

    # Testing
    test_loss, test_acc = model.evaluate(image_data_gen['test'])
    print("[INFO] Model: Test Loss:", test_loss, "Test Accuracy:", test_acc)
    print("[INFO] Testing done!")
    return test_loss, test_acc

def predict_class(model, image:Path):
    """
    This function predicts the class of the given image.

    Params:
        model: Model to be tested
        image: Image to be predicted
    
    Returns:
        predicted_class_idx: Predicted class index
    """

    # Load the image, rescale 1./255 and resize to (300, 300)
    INPUT_SHAPE = (224, 224) # (300, 300) for MobileNetV2, others (224, 224)
    img = keras.preprocessing.image.load_img(image, target_size=INPUT_SHAPE)
    img_array = keras.preprocessing.image.img_to_array(img)
    img_array = tf.expand_dims(img_array, 0)  # Create batch axis
    img_array = img_array / 255.0

    # Predict the class
    predictions = model.predict(img_array)
    #predictions_prob = tf.nn.softmax(predictions[0])
    #print("[INFO] Predictions:", predictions_prob)
    predicted_class_idx = tf.argmax(predictions[0]).numpy()

    return predicted_class_idx

if __name__ == "__main__":
    # construct the argument parser and parse the arguments
    ap = argparse.ArgumentParser()
    ap.add_argument("-d", "--data_dir", required=True,
        help="path to the data directory for train, test mode. Single image path for predict mode")
    ap.add_argument("-n", "--model_name", required=True,
        help="name of the model to be created, available models: VGG19, VGG16_A, VGG16_B, INCEPTIONV3, MOBILENETV2, RESNET101V2")
    ap.add_argument("-m", "--mode", required=True,
        help="mode of the program, train or test or predict")
    ap.add_argument("-e", "--epochs", required=False,
        help="number of epochs", default=10)
    ap.add_argument("-p", "--patience", required=False,
        help="patience for early stopping", default=5)
    ap.add_argument("-lr", "--learning_rate", required=False,
        help="learning rate", default=0.001)
    args = vars(ap.parse_args())

    # Check if the given data_dir exists
    if not os.path.exists(args["data_dir"]):
        print(f"[ERROR] The given data_dir {args['data_dir']} doesn't exist!")
        exit()
    
    # Check if the given model_name is valid
    if args["model_name"] not in ["VGG19", "VGG16_A", "VGG16_B", "INCEPTIONV3", "MOBILENETV2", "RESNET101V2"]:
        print(f"[ERROR] The given model_name {args['model_name']} is invalid!")
        exit()
    
    # Check if the given mode is valid
    if args["mode"] not in ["train", "test", "predict"]:
        print(f"[ERROR] The given mode {args['mode']} is invalid!")
        exit()
    
    # Create/load model
    if args["mode"] == "train":
        # Create data generators
        image_data_gen = data_generator(Path(args["data_dir"]), args["mode"])

        # Save the class names into a .txt file
        class_names = list(image_data_gen['train'].class_indices.keys())

        # save it into "class_names.txt" file
        file_name = "class_names.txt"
        with open(file_name, 'w') as f:
            for item in class_names:
                f.write("%s\n" % item)

        # Create the model
        model = model(args["model_name"], out_features=len(image_data_gen['train'].class_indices))
        
        # Train model
        history = train(model, image_data_gen, args["model_name"], epochs=int(args["epochs"]), patience=int(args["patience"]), learning_rate=float(args["learning_rate"]))

        # Test model
        test_loss, test_acc = test(model, image_data_gen)

    elif args["mode"] == "test":
        # Create data generators
        image_data_gen = data_generator(Path(args["data_dir"]), args["mode"])

        # Load the model
        model = keras.models.load_model(args["model_name"]+".h5")
        
        # Test model
        test_loss, test_acc = test(model, image_data_gen)
    
    elif args["mode"] == "predict":
        # Load the model
        print("[INFO] Loading model...")
        model = keras.models.load_model(args["model_name"]+".h5")

        # Retrive the class name from class_names.txt file
        print("[INFO] Loading Class names...")
        file_name = "class_names.txt"
        with open(file_name, 'r') as f:
            class_names = f.readlines()
            class_names = [x.strip() for x in class_names]

        # Start timer
        start = timer()
        
        # Predict class
        predicted_class_idx = predict_class(model, Path(args["data_dir"]))
        
        # Stop timer
        end = timer()
        
        # Print the predicted class
        print("[INFO] Predicted class:", class_names[predicted_class_idx])
        print("[INFO] Time taken:", end - start, "seconds")


# Call this file like this:
# python Model.py -d data -n INCEPTIONV3 -m train
# python Model.py -d data -n INCEPTIONV3 -m test
# python Model.py -n INCEPTIONV3 -m predict -d data/test/0/1.jpg