import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import Sequential, Input
from tensorflow.keras.layers import Conv2D, MaxPooling2D, Flatten, Dense, Dropout
from tensorflow.keras.callbacks import ModelCheckpoint, ReduceLROnPlateau, CSVLogger, TensorBoard

# Dataset paths
data_base_dir = "dataset/"
train_batch_size = 64
target_image_size = (224, 224)

# Data augmentation and preprocessing
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=20,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    validation_split=0.2
)

# Train data generator
train_generator = train_datagen.flow_from_directory(
    data_base_dir,
    target_size=target_image_size,
    batch_size=train_batch_size,
    class_mode='binary',
    subset='training'
)

# Validation data generator
val_generator = train_datagen.flow_from_directory(
    data_base_dir,
    target_size=target_image_size,
    batch_size=train_batch_size,
    class_mode='binary',
    subset='validation'
)

# CNN Model Architecture
model = Sequential([
    Input(shape=(224, 224, 3)),
    Conv2D(32, (3,3), activation='hard_silu', padding='same'),
    MaxPooling2D((2,2)),

    Conv2D(64, (3,3), activation='hard_silu', padding='same'),
    MaxPooling2D((2,2)),

    Conv2D(128, (3,3), activation='hard_silu', padding='same'),
    MaxPooling2D((2,2)),

    Flatten(),
    Dense(128, activation='hard_silu'),
    Dropout(0.5),
    Dense(64, activation='hard_silu'),
    Dropout(0.5),
    Dense(1, activation='sigmoid')
])

# Compile the model
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    loss='binary_crossentropy',
    metrics=['accuracy']
)

# Callbacks
checkpoint = ModelCheckpoint('best_model.keras', monitor='val_accuracy', save_best_only=True, verbose=1)
reduce_lr = ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, verbose=1)
csv_logger = CSVLogger('training_log_hard_silu.csv')
tensorboard = TensorBoard(log_dir='logs', histogram_freq=1)

# Model training
history = model.fit(
    train_generator,
    epochs=50,
    validation_data=val_generator,
    callbacks=[checkpoint, reduce_lr, csv_logger, tensorboard]
)

# Save the final model
model.save('temp/final_model.keras')
